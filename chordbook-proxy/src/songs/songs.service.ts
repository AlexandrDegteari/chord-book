import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { Song } from '../database/song.model';
import { ScraperService, Song as ScrapedSong, RateLimitError } from '../scraper/scraper.service';

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
    // 1. Search our own DB first (fast autocomplete)
    const dbResults = await this.searchDb(query);

    const formatted = dbResults.map((s) => ({
      id: s.externalId || s.id,
      title: s.title,
      artist: s.artist,
      url: s.url || '',
    }));

    // 2. Only fall back to scraper if DB returned no results
    if (formatted.length === 0) {
      try {
        const scraped = await this.scraperService.search(query);
        this.saveSongsInBackground(scraped);

        for (const s of scraped) {
          formatted.push(s);
        }
      } catch (err) {
        this.logger.warn(`Scraper search failed: ${err.message}`);
      }
    } else {
      // DB had results — still save any new scraper results in background
      // but don't block on it and don't add to response
      this.scraperService.search(query)
        .then(scraped => this.saveSongsInBackground(scraped))
        .catch(() => {});
    }

    return formatted;
  }

  private async searchDb(query: string): Promise<Song[]> {
    const words = query.trim().split(/\s+/).filter(w => w.length > 0);
    const searchConditions: any[] = [];

    // Single-string match against title and artist
    searchConditions.push(
      { title: { [Op.iLike]: `%${query}%` } },
      { artist: { [Op.iLike]: `%${query}%` } },
    );

    // Multi-word: each word must match in title OR artist (cross-column)
    if (words.length > 1) {
      const wordConditions = words.map(word => ({
        [Op.or]: [
          { title: { [Op.iLike]: `%${word}%` } },
          { artist: { [Op.iLike]: `%${word}%` } },
        ],
      }));
      searchConditions.push({ [Op.and]: wordConditions });
    }

    // Cyrillic transliteration support
    if (this.isCyrillic(query)) {
      const translit = this.transliterate(query);
      searchConditions.push(
        { title: { [Op.iLike]: `%${translit}%` } },
        { artist: { [Op.iLike]: `%${translit}%` } },
      );

      const translitWords = translit.trim().split(/\s+/).filter(w => w.length > 0);
      if (translitWords.length > 1) {
        const wordConditions = translitWords.map(word => ({
          [Op.or]: [
            { title: { [Op.iLike]: `%${word}%` } },
            { artist: { [Op.iLike]: `%${word}%` } },
          ],
        }));
        searchConditions.push({ [Op.and]: wordConditions });
      }
    }

    const escapedQuery = query.replace(/'/g, "''");
    return this.songModel.findAll({
      where: {
        status: 'active',
        [Op.or]: searchConditions,
      },
      limit: 50,
      order: [
        [this.songModel.sequelize!.literal(`CASE WHEN artist ILIKE '%${escapedQuery}%' THEN 0 ELSE 1 END`), 'ASC'],
        ['artist', 'ASC'],
        ['title', 'ASC'],
      ],
    });
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
      // Only persist if we actually got content
      if (scraped.sections && scraped.sections.length > 0) {
        await this.upsertFromScraped(scraped);
      }
      return scraped;
    } catch (err) {
      if (err instanceof RateLimitError) {
        this.logger.warn('Scraper rate limited (429) for getSong');
        // Propagate 429 so client can show "server busy" UI
        throw err;
      }
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
      // Only persist if we actually got content
      if (scraped.sections && scraped.sections.length > 0) {
        await this.upsertFromScraped(scraped);
      }
      return scraped;
    } catch (err) {
      if (err instanceof RateLimitError) {
        this.logger.warn('Scraper rate limited (429) for getSongByUrl');
        // Propagate 429 so client can show "server busy" UI
        throw err;
      }
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
        const updateData: any = {
          url: scraped.url,
          scrapedAt: new Date(),
        };

        // Only update sections if scraped data has content
        // Never overwrite non-empty sections with empty ones
        const scrapedHasSections = Array.isArray(scraped.sections) && scraped.sections.length > 0;
        if (scrapedHasSections) {
          updateData.sections = scraped.sections;
        }

        // Only update names if scraped names contain Cyrillic or existing names don't
        const hasCyrillic = (s: string) => /[а-яёА-ЯЁіїєґІЇЄҐ]/.test(s);
        if (hasCyrillic(scraped.title) || !hasCyrillic(existing.title)) {
          updateData.title = scraped.title;
          updateData.artist = scraped.artist;
        }

        await existing.update(updateData);
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
