import { Song } from '../database/song.model';
import { ScraperService } from '../scraper/scraper.service';
export declare class CronService {
    private readonly songModel;
    private readonly scraperService;
    private readonly logger;
    private isRunning;
    private backfillRunning;
    private backfillShouldStop;
    private backfillProgress;
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
    getBackfillStatus(): {
        total: number;
        processed: number;
        updated: number;
        failed: number;
        running: boolean;
    };
    stopBackfill(): {
        error: string;
        message?: undefined;
    } | {
        message: string;
        error?: undefined;
    };
    backfillSections(limit?: number, artistFilter?: string): Promise<{
        stopped: boolean;
        total: number;
        processed: number;
        updated: number;
        failed: number;
    } | {
        error: string;
    }>;
}
