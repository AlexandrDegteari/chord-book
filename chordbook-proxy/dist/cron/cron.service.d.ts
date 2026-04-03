import { Song } from '../database/song.model';
import { ScraperService } from '../scraper/scraper.service';
export declare class CronService {
    private readonly songModel;
    private readonly scraperService;
    private readonly logger;
    private isRunning;
    constructor(songModel: typeof Song, scraperService: ScraperService);
    getStatus(): {
        isRunning: boolean;
    };
    fullScrape(): Promise<{
        totalArtists: number;
        totalSongs: number;
        skipped: number;
        failed: number;
    } | {
        error: string;
    }>;
}
