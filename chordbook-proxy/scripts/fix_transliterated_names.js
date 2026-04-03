#!/usr/bin/env node
/**
 * Fix transliterated song names by fetching real Cyrillic names from mychords.net autocomplete API.
 *
 * Run from a machine that is NOT banned by mychords.net.
 * Requires SSH tunnel: ssh -L 5433:localhost:5432 root@46.225.124.82
 *
 * Usage: node scripts/fix_transliterated_names.js
 */

const { Client } = require('pg');
const https = require('https');

const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5433'),
  user: process.env.DB_USER || 'sixstrings',
  password: process.env.DB_PASS || 'SixStr1ngs2024',
  database: process.env.DB_NAME || 'sixstrings_db',
};

const DELAY_MS = parseInt(process.env.DELAY_MS || '500');

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function hasCyrillic(text) {
  return /[а-яёА-ЯЁіїєґІЇЄҐ]/.test(text);
}

function fetchAutocomplete(query) {
  return new Promise((resolve) => {
    const url = `https://mychords.net/en/ajax/autocomplete?q=${encodeURIComponent(query)}`;
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
        'X-Requested-With': 'XMLHttpRequest',
      },
      timeout: 10000,
    }, (res) => {
      if (res.statusCode === 429) { resolve({ status: 429 }); return; }
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try { resolve({ status: 200, data: JSON.parse(data) }); }
        catch { resolve(null); }
      });
    });
    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
  });
}

function findRealName(autocompleteData, externalId) {
  if (!autocompleteData?.suggestions) return null;

  for (const suggestion of autocompleteData.suggestions) {
    const url = suggestion.data?.url || '';
    const group = suggestion.data?.group || '';
    const value = suggestion.value || '';

    if (group === 'Songs' && url.includes(`/${externalId}-`)) {
      const parts = value.split(' - ');
      if (parts.length > 1) {
        return {
          artist: parts[0].trim(),
          title: parts.slice(1).join(' - ').trim(),
        };
      }
    }
  }
  return null;
}

async function main() {
  const client = new Client(DB_CONFIG);
  await client.connect();
  console.log('Connected to database');

  // Fetch all songs with externalId in batches using cursor-style pagination
  let lastId = '00000000-0000-0000-0000-000000000000';
  let totalProcessed = 0;
  let fixed = 0;
  let skipped = 0;
  let rateLimited = 0;

  while (true) {
    const batch = await client.query(
      `SELECT id, "externalId", title, artist FROM songs
       WHERE status = 'active' AND "externalId" IS NOT NULL AND id > $1
       ORDER BY id LIMIT 500`,
      [lastId],
    );

    if (batch.rows.length === 0) break;

    // Filter in JS: only Latin-only songs
    const needsFixing = batch.rows.filter(
      (s) => !hasCyrillic(s.title) && !hasCyrillic(s.artist),
    );

    for (const song of needsFixing) {
      const result = await fetchAutocomplete(song.externalId);

      if (result === null) {
        // Network error, skip
        skipped++;
        continue;
      }

      if (result.status === 429) {
        rateLimited++;
        console.log(`Rate limited — waiting 30s (total: ${rateLimited})`);
        await sleep(30000);
        continue;
      }

      const realName = findRealName(result.data, song.externalId);

      if (realName && (hasCyrillic(realName.title) || hasCyrillic(realName.artist))) {
        await client.query(
          `UPDATE songs SET title = $1, artist = $2 WHERE id = $3`,
          [realName.title, realName.artist, song.id],
        );
        fixed++;
      } else {
        skipped++;
      }

      totalProcessed++;
      if (totalProcessed % 50 === 0) {
        console.log(`Processed: ${totalProcessed}, Fixed: ${fixed}, Skipped: ${skipped}, Rate limited: ${rateLimited}`);
      }

      await sleep(DELAY_MS);
    }

    lastId = batch.rows[batch.rows.length - 1].id;

    // Skip songs that already have Cyrillic (no API call needed)
    const alreadyCyrillic = batch.rows.length - needsFixing.length;
    if (alreadyCyrillic > 0) {
      // These are fine, just continue
    }
  }

  console.log(`\nDone! Processed: ${totalProcessed}, Fixed: ${fixed}, Skipped: ${skipped}, Rate limited: ${rateLimited}`);
  await client.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
