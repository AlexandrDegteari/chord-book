import { Song } from '../database/song.model';
import { ScraperService, Song as ScrapedSong } from '../scraper/scraper.service';
export declare class SongsService {
    private readonly songModel;
    private readonly scraperService;
    private readonly logger;
    constructor(songModel: typeof Song, scraperService: ScraperService);
    private transliterate;
    private isCyrillic;
    search(query: string): Promise<{
        id: string;
        title: string;
        artist: string;
        url: string;
    }[]>;
    getSong(id: string): Promise<{
        id: string;
        title: string;
        artist: string;
        url: string;
        sections: any;
    }>;
    getSongByUrl(url: string): Promise<{
        id: string;
        title: string;
        artist: string;
        url: string;
        sections: any;
    }>;
    upsertFromScraped(scraped: ScrapedSong): Promise<Song | null>;
    findById(id: string): Promise<Song | null>;
    private hasSections;
    private formatSong;
    private saveSongsInBackground;
}
