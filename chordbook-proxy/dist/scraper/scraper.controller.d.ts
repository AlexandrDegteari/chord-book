import { ScraperService } from './scraper.service';
export declare class ScraperController {
    private readonly scraperService;
    constructor(scraperService: ScraperService);
    search(query: string): Promise<import("./scraper.service").SearchResult[]>;
    getSong(id: string): Promise<import("./scraper.service").Song>;
    getSongByUrl(url: string): Promise<import("./scraper.service").Song | {
        error: string;
    }>;
}
