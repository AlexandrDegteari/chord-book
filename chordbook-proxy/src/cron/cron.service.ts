import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Sequelize } from 'sequelize';
import { Song } from '../database/song.model';
import { ScraperService, RateLimitError } from '../scraper/scraper.service';

@Injectable()
export class CronService {
  private readonly logger = new Logger(CronService.name);
  private isRunning = false;

  // Backfill state
  private backfillRunning = false;
  private backfillShouldStop = false;
  private backfillProgress = { total: 0, processed: 0, updated: 0, failed: 0 };

  constructor(
    @InjectModel(Song) private readonly songModel: typeof Song,
    private readonly scraperService: ScraperService,
  ) {}

  getStatus() {
    return { isRunning: this.isRunning };
  }

  async fullScrape() {
    if (this.isRunning) {
      return { error: 'Scrape already running' };
    }

    this.isRunning = true;
    this.logger.log('Starting FULL scrape of mychords.net...');

    let totalArtists = 0;
    let totalSongs = 0;
    let skipped = 0;
    let failed = 0;

    try {
      const artists = await this.scraperService.getAllArtists();
      totalArtists = artists.length;
      this.logger.log(`Found ${totalArtists} artists to scrape`);

      for (let i = 0; i < artists.length; i++) {
        const artist = artists[i];
        try {
          const songs = await this.scraperService.getArtistSongs(artist.url, artist.name);
          this.logger.log(`[${i + 1}/${totalArtists}] ${artist.name}: ${songs.length} songs`);

          for (const song of songs) {
            const exists = await this.songModel.findOne({
              where: { externalId: song.id },
            });

            if (exists && Array.isArray(exists.sections) && exists.sections.length > 0) {
              skipped++;
              continue;
            }

            try {
              const fullSong = await this.scraperService.getSongByUrl(song.url);
              const hasSections = Array.isArray(fullSong.sections) && fullSong.sections.length > 0;

              // Skip saving if we got empty content (likely rate limited)
              if (!hasSections) {
                failed++;
                continue;
              }

              const hasCyrillic = (s: string) => /[а-яёА-ЯЁіїєґІЇЄҐ]/.test(s);

              if (exists) {
                const updateData: any = {
                  url: fullSong.url,
                  sections: fullSong.sections,
                  scrapedAt: new Date(),
                };
                // Only update names if new names are Cyrillic or existing aren't
                if (hasCyrillic(fullSong.title) || !hasCyrillic(exists.title)) {
                  updateData.title = fullSong.title;
                  updateData.artist = fullSong.artist;
                }
                await exists.update(updateData);
              } else {
                await this.songModel.create({
                  externalId: fullSong.id,
                  title: fullSong.title,
                  artist: fullSong.artist,
                  url: fullSong.url,
                  sections: fullSong.sections,
                  source: 'scraped',
                  status: 'pending',
                  scrapedAt: new Date(),
                });
              }

              totalSongs++;

              if (totalSongs % 50 === 0) {
                this.logger.log(`Progress: ${totalSongs} songs scraped, ${skipped} skipped, ${failed} failed`);
              }
            } catch (err) {
              failed++;
              if (err instanceof RateLimitError) {
                this.logger.warn(`Rate limited — pausing for 60s`);
                await new Promise((r) => setTimeout(r, 60000));
              } else {
                this.logger.warn(`Failed: ${song.url} - ${err.message}`);
              }
            }

            await new Promise((r) => setTimeout(r, 3000));
          }

          await new Promise((r) => setTimeout(r, 2000));
        } catch (err) {
          this.logger.warn(`Failed artist "${artist.name}": ${err.message}`);
        }
      }
    } finally {
      this.isRunning = false;
    }

    const result = { totalArtists, totalSongs, skipped, failed };
    this.logger.log(`Full scrape complete: ${JSON.stringify(result)}`);
    return result;
  }

  getBackfillStatus() {
    return { running: this.backfillRunning, ...this.backfillProgress };
  }

  stopBackfill() {
    if (!this.backfillRunning) {
      return { error: 'Backfill is not running' };
    }
    this.backfillShouldStop = true;
    return { message: 'Stop signal sent, will stop after current song' };
  }

  async backfillSections(limit = 5000, artistFilter?: string) {
    if (this.backfillRunning) {
      return { error: 'Backfill already running' };
    }

    this.backfillRunning = true;
    this.backfillShouldStop = false;
    this.backfillProgress = { total: 0, processed: 0, updated: 0, failed: 0 };

    this.logger.log(`Starting backfill sections (limit=${limit}${artistFilter ? `, artist="${artistFilter}"` : ''})...`);

    try {
      // Build where clause
      const emptySectionsCondition = "(sections IS NULL OR sections::text = '[]' OR sections::text = 'null')";
      const artistCondition = artistFilter
        ? ` AND artist ILIKE '%${artistFilter.replace(/'/g, "''")}%'`
        : '';
      const whereClause = Sequelize.literal(emptySectionsCondition + artistCondition);

      // Count total songs needing backfill
      const totalNeeding = await this.songModel.count({ where: whereClause as any });
      this.backfillProgress.total = Math.min(totalNeeding, limit);
      this.logger.log(`Found ${totalNeeding} songs without sections, will process ${this.backfillProgress.total}`);

      const batchSize = 100;
      let processed = 0;

      while (processed < limit && !this.backfillShouldStop) {
        const songs = await this.songModel.findAll({
          where: whereClause as any,
          order: [['id', 'ASC']],
          limit: batchSize,
        });

        if (songs.length === 0) break;

        for (const song of songs) {
          if (processed >= limit || this.backfillShouldStop) break;

          if (!song.url) {
            this.backfillProgress.failed++;
            processed++;
            this.backfillProgress.processed = processed;
            continue;
          }

          try {
            const scraped = await this.scraperService.getSongByUrl(song.url);
            const hasSections = Array.isArray(scraped.sections) && scraped.sections.length > 0;

            if (hasSections) {
              const hasCyrillic = (s: string) => /[а-яёА-ЯЁіїєґІЇЄҐ]/.test(s);
              const updateData: any = {
                sections: scraped.sections,
                scrapedAt: new Date(),
              };
              // Update names if scraped has Cyrillic or existing doesn't
              if (hasCyrillic(scraped.title) || !hasCyrillic(song.title)) {
                updateData.title = scraped.title;
                updateData.artist = scraped.artist;
              }
              await song.update(updateData);
              this.backfillProgress.updated++;
              this.logger.log(`[${processed + 1}] OK: ${scraped.artist} - ${scraped.title} (${scraped.sections.length} sections)`);
            } else {
              this.backfillProgress.failed++;
              this.logger.warn(`[${processed + 1}] EMPTY: ${song.url}`);
            }
          } catch (err) {
            this.backfillProgress.failed++;
            if (err instanceof RateLimitError) {
              this.logger.warn('Rate limited during backfill — waiting 90s');
              await new Promise((r) => setTimeout(r, 90000));
            } else {
              this.logger.warn(`Backfill failed for ${song.url}: ${err.message}`);
            }
          }

          processed++;
          this.backfillProgress.processed = processed;

          // Extra pause every 50 songs to be gentle
          if (processed % 50 === 0) {
            this.logger.log(`Backfill progress: ${processed}/${this.backfillProgress.total} (updated=${this.backfillProgress.updated}, failed=${this.backfillProgress.failed})`);
            await new Promise((r) => setTimeout(r, 30000));
          }
        }
      }
    } finally {
      this.backfillRunning = false;
    }

    const result = { ...this.backfillProgress, stopped: this.backfillShouldStop };
    this.logger.log(`Backfill complete: ${JSON.stringify(result)}`);
    return result;
  }
}
