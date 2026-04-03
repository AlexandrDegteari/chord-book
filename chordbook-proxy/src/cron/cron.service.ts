import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Song } from '../database/song.model';
import { ScraperService, RateLimitError } from '../scraper/scraper.service';

@Injectable()
export class CronService {
  private readonly logger = new Logger(CronService.name);
  private isRunning = false;

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
}
