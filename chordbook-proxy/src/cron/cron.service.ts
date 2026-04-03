import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectModel } from '@nestjs/sequelize';
import { Song } from '../database/song.model';
import { ScraperService } from '../scraper/scraper.service';

@Injectable()
export class CronService {
  private readonly logger = new Logger(CronService.name);
  private isRunning = false;

  constructor(
    @InjectModel(Song) private readonly songModel: typeof Song,
    private readonly scraperService: ScraperService,
  ) {}

  // Every Sunday at 3 AM
  @Cron('0 3 * * 0')
  async weeklySync() {
    this.logger.log('Starting weekly sync with mychords.net...');
    await this.syncNewSongs();
    this.logger.log('Weekly sync completed');
  }

  async syncNewSongs() {
    const artists = await this.songModel.findAll({
      attributes: ['artist'],
      where: { source: 'scraped', status: 'active' },
      group: ['artist'],
    });

    let newSongsCount = 0;

    for (const { artist } of artists) {
      try {
        const results = await this.scraperService.search(artist);

        for (const result of results) {
          const exists = await this.songModel.findOne({
            where: { externalId: result.id },
          });

          if (!exists) {
            try {
              const fullSong = await this.scraperService.getSongByUrl(result.url);

              await this.songModel.create({
                externalId: fullSong.id,
                title: fullSong.title,
                artist: fullSong.artist,
                url: fullSong.url,
                sections: fullSong.sections,
                source: 'scraped',
                status: 'active',
                scrapedAt: new Date(),
              });

              newSongsCount++;
              this.logger.log(`Added: ${fullSong.artist} - ${fullSong.title}`);
            } catch (err) {
              this.logger.warn(`Failed to scrape ${result.url}: ${err.message}`);
            }

            await new Promise((r) => setTimeout(r, 2000));
          }
        }

        await new Promise((r) => setTimeout(r, 1000));
      } catch (err) {
        this.logger.warn(`Failed to sync artist "${artist}": ${err.message}`);
      }
    }

    this.logger.log(`Sync complete. Added ${newSongsCount} new songs`);
    return { newSongsCount };
  }

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
      // Get all artists from alphabetical index
      const artists = await this.scraperService.getAllArtists();
      totalArtists = artists.length;
      this.logger.log(`Found ${totalArtists} artists to scrape`);

      for (let i = 0; i < artists.length; i++) {
        const artist = artists[i];
        try {
          // Get song list for this artist
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

              if (exists) {
                await exists.update({
                  title: fullSong.title,
                  artist: fullSong.artist,
                  url: fullSong.url,
                  sections: fullSong.sections,
                  scrapedAt: new Date(),
                });
              } else {
                await this.songModel.create({
                  externalId: fullSong.id,
                  title: fullSong.title,
                  artist: fullSong.artist,
                  url: fullSong.url,
                  sections: fullSong.sections,
                  source: 'scraped',
                  status: 'active',
                  scrapedAt: new Date(),
                });
              }

              totalSongs++;

              if (totalSongs % 50 === 0) {
                this.logger.log(`Progress: ${totalSongs} songs scraped, ${skipped} skipped, ${failed} failed`);
              }
            } catch (err) {
              failed++;
              this.logger.warn(`Failed: ${song.url} - ${err.message}`);
            }

            // Rate limit: 3s between song scrapes
            await new Promise((r) => setTimeout(r, 3000));
          }

          // Delay between artists
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
