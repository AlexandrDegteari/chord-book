#!/usr/bin/env node
// Usage: node update_names.js < real_names.json
// Reads JSON array of {id, artist, title} and updates songs in PostgreSQL

const { Client } = require('pg');

async function main() {
  let input = '';
  for await (const chunk of process.stdin) {
    input += chunk;
  }

  const songs = JSON.parse(input);
  console.log(`Loaded ${songs.length} songs to update`);

  const client = new Client({
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT || '5432'),
    user: process.env.DATABASE_USER || 'sixstrings',
    password: process.env.DATABASE_PASSWORD || 'SixStr1ngs2024',
    database: process.env.DATABASE_NAME || 'sixstrings_db',
  });

  await client.connect();
  console.log('Connected to DB');

  let updated = 0;
  let notFound = 0;

  // Process in batches of 100
  for (let i = 0; i < songs.length; i += 100) {
    const batch = songs.slice(i, i + 100);

    for (const song of batch) {
      try {
        const result = await client.query(
          'UPDATE songs SET title = $1, artist = $2, "updatedAt" = NOW() WHERE "externalId" = $3',
          [song.title, song.artist, song.id]
        );
        if (result.rowCount > 0) updated++;
        else notFound++;
      } catch (e) {
        notFound++;
      }
    }

    if ((i + 100) % 500 === 0) {
      console.log(`Progress: ${i + 100}/${songs.length} updated:${updated} notFound:${notFound}`);
    }
  }

  console.log(`Done! Updated: ${updated}, Not found: ${notFound}, Total: ${songs.length}`);
  await client.end();
}

main().catch(console.error);
