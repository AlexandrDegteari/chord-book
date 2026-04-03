import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { Song } from '../database/song.model';
import { ScraperService, Song as ScrapedSong } from '../scraper/scraper.service';

@Injectable()
export class SongsService {
  private readonly logger = new Logger(SongsService.name);

  constructor(
    @InjectModel(Song) private readonly songModel: typeof Song,
    private readonly scraperService: ScraperService,
  ) {}

  private transliterate(text: string): string {
    const map: Record<string, string> = {
      'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'zh',
      'з':'z','и':'i','й':'j','к':'k','л':'l','м':'m','н':'n','о':'o',
      'п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'h','ц':'c',
      'ч':'ch','ш':'sh','щ':'sch','ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya',
    };
    return text.toLowerCase().split('').map(c => map[c] ?? c).join('');
  }

  private isCyrillic(text: string): boolean {
    return /[а-яё]/i.test(text);
  }

  async search(query: string) {
    // Build search conditions — include transliterated query for cyrillic input
    const searchConditions: any[] = [
      { title: { [Op.iLike]: `%${query}%` } },
      { artist: { [Op.iLike]: `%${query}%` } },
    ];

    if (this.isCyrillic(query)) {
      const translit = this.transliterate(query);
      searchConditions.push(
        { title: { [Op.iLike]: `%${translit}%` } },
        { artist: { [Op.iLike]: `%${translit}%` } },
      );
    }

    const dbResults = await this.songModel.findAll({
      where: {
        status: 'active',
        [Op.or]: searchConditions,
      },
      limit: 30,
      order: [['title', 'ASC']],
    });

    const formatted = dbResults.map((s) => ({
      id: s.externalId || s.id,
      title: s.title,
      artist: s.artist,
      url: s.url || '',
    }));

    // Also try scraper in background to supplement results
    // But never fail if scraper is down
    try {
      const scraped = await this.scraperService.search(query);
      this.saveSongsInBackground(scraped);

      // Merge: DB results first, then scraper results not already in DB
      const dbIds = new Set(formatted.map((r) => r.id));
      for (const s of scraped) {
        if (!dbIds.has(s.id)) {
          formatted.push(s);
        }
      }
    } catch (err) {
      this.logger.warn(`Scraper search failed (returning DB results only): ${err.message}`);
    }

    return formatted;
  }

  async getSong(id: string) {
    // Try DB by externalId
    const dbSong = await this.songModel.findOne({
      where: { externalId: id, status: 'active' },
    });

    if (dbSong && this.hasSections(dbSong)) {
      return this.formatSong(dbSong);
    }

    // Try DB by UUID
    const dbSongById = await this.songModel.findOne({
      where: { id, status: 'active' },
    });

    if (dbSongById && this.hasSections(dbSongById)) {
      return this.formatSong(dbSongById);
    }

    // Try scraper, but don't crash if it fails
    try {
      const scraped = await this.scraperService.getSong(id);
      await this.upsertFromScraped(scraped);
      return scraped;
    } catch (err) {
      this.logger.warn(`Scraper getSong failed: ${err.message}`);
      // Return DB song even without sections (better than nothing)
      const fallback = dbSong || dbSongById;
      if (fallback) return this.formatSong(fallback);
      throw err;
    }
  }

  async getSongByUrl(url: string) {
    // Try DB by URL
    const dbSong = await this.songModel.findOne({
      where: { url, status: 'active' },
    });

    if (dbSong && this.hasSections(dbSong)) {
      return this.formatSong(dbSong);
    }

    // Try DB by external ID from URL
    const idMatch = url.match(/\/(\d+)-/);
    let dbSongByExtId: Song | null = null;
    if (idMatch) {
      dbSongByExtId = await this.songModel.findOne({
        where: { externalId: idMatch[1], status: 'active' },
      });
      if (dbSongByExtId && this.hasSections(dbSongByExtId)) {
        return this.formatSong(dbSongByExtId);
      }
    }

    // Try scraper, but don't crash if it fails
    try {
      const scraped = await this.scraperService.getSongByUrl(url);
      await this.upsertFromScraped(scraped);
      return scraped;
    } catch (err) {
      this.logger.warn(`Scraper getSongByUrl failed: ${err.message}`);
      const fallback = dbSong || dbSongByExtId;
      if (fallback) return this.formatSong(fallback);
      throw err;
    }
  }

  async upsertFromScraped(scraped: ScrapedSong) {
    try {
      const existing = await this.songModel.findOne({
        where: { externalId: scraped.id },
      });

      if (existing) {
        await existing.update({
          title: scraped.title,
          artist: scraped.artist,
          url: scraped.url,
          sections: scraped.sections,
          scrapedAt: new Date(),
        });
        return existing;
      }

      return await this.songModel.create({
        externalId: scraped.id,
        title: scraped.title,
        artist: scraped.artist,
        url: scraped.url,
        sections: scraped.sections,
        source: 'scraped',
        status: 'active',
        scrapedAt: new Date(),
      });
    } catch (err) {
      this.logger.error('Failed to upsert song', err);
      return null;
    }
  }

  async findById(id: string) {
    return this.songModel.findByPk(id);
  }

  private hasSections(dbSong: Song): boolean {
    return Array.isArray(dbSong.sections) && dbSong.sections.length > 0;
  }

  private formatSong(dbSong: Song) {
    return {
      id: dbSong.externalId || dbSong.id,
      title: dbSong.title,
      artist: dbSong.artist,
      url: dbSong.url || '',
      sections: dbSong.sections,
    };
  }

  private async saveSongsInBackground(results: Array<{ id: string; title: string; artist: string; url: string }>) {
    for (const r of results) {
      try {
        const exists = await this.songModel.findOne({ where: { externalId: r.id } });
        if (!exists) {
          await this.songModel.create({
            externalId: r.id,
            title: r.title,
            artist: r.artist,
            url: r.url,
            sections: [],
            source: 'scraped',
            status: 'active',
            scrapedAt: new Date(),
          });
        }
      } catch {
        // Skip duplicates
      }
    }
  }
}
