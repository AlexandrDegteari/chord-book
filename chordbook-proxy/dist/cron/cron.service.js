"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var CronService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.CronService = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const sequelize_2 = require("sequelize");
const song_model_1 = require("../database/song.model");
const scraper_service_1 = require("../scraper/scraper.service");
let CronService = CronService_1 = class CronService {
    songModel;
    scraperService;
    logger = new common_1.Logger(CronService_1.name);
    isRunning = false;
    backfillRunning = false;
    backfillShouldStop = false;
    backfillProgress = { total: 0, processed: 0, updated: 0, failed: 0 };
    constructor(songModel, scraperService) {
        this.songModel = songModel;
        this.scraperService = scraperService;
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
                            if (!hasSections) {
                                failed++;
                                continue;
                            }
                            const hasCyrillic = (s) => /[а-яёА-ЯЁіїєґІЇЄҐ]/.test(s);
                            if (exists) {
                                const updateData = {
                                    url: fullSong.url,
                                    sections: fullSong.sections,
                                    scrapedAt: new Date(),
                                };
                                if (hasCyrillic(fullSong.title) || !hasCyrillic(exists.title)) {
                                    updateData.title = fullSong.title;
                                    updateData.artist = fullSong.artist;
                                }
                                await exists.update(updateData);
                            }
                            else {
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
                        }
                        catch (err) {
                            failed++;
                            if (err instanceof scraper_service_1.RateLimitError) {
                                this.logger.warn(`Rate limited — pausing for 60s`);
                                await new Promise((r) => setTimeout(r, 60000));
                            }
                            else {
                                this.logger.warn(`Failed: ${song.url} - ${err.message}`);
                            }
                        }
                        await new Promise((r) => setTimeout(r, 3000));
                    }
                    await new Promise((r) => setTimeout(r, 2000));
                }
                catch (err) {
                    this.logger.warn(`Failed artist "${artist.name}": ${err.message}`);
                }
            }
        }
        finally {
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
    async backfillSections(limit = 5000, artistFilter) {
        if (this.backfillRunning) {
            return { error: 'Backfill already running' };
        }
        this.backfillRunning = true;
        this.backfillShouldStop = false;
        this.backfillProgress = { total: 0, processed: 0, updated: 0, failed: 0 };
        this.logger.log(`Starting backfill sections (limit=${limit}${artistFilter ? `, artist="${artistFilter}"` : ''})...`);
        try {
            const emptySectionsCondition = "sections IS NULL OR sections::text = '[]' OR sections::text = 'null'";
            const whereClause = artistFilter
                ? { [sequelize_2.Op.and]: [
                        sequelize_2.Sequelize.literal(emptySectionsCondition),
                        { artist: { [sequelize_2.Op.iLike]: `%${artistFilter}%` } },
                    ] }
                : sequelize_2.Sequelize.literal(emptySectionsCondition);
            const totalNeeding = await this.songModel.count({ where: whereClause });
            this.backfillProgress.total = Math.min(totalNeeding, limit);
            this.logger.log(`Found ${totalNeeding} songs without sections, will process ${this.backfillProgress.total}`);
            const batchSize = 100;
            let processed = 0;
            while (processed < limit && !this.backfillShouldStop) {
                const songs = await this.songModel.findAll({
                    where: whereClause,
                    order: [['id', 'ASC']],
                    limit: batchSize,
                });
                if (songs.length === 0)
                    break;
                for (const song of songs) {
                    if (processed >= limit || this.backfillShouldStop)
                        break;
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
                            const hasCyrillic = (s) => /[а-яёА-ЯЁіїєґІЇЄҐ]/.test(s);
                            const updateData = {
                                sections: scraped.sections,
                                scrapedAt: new Date(),
                            };
                            if (hasCyrillic(scraped.title) || !hasCyrillic(song.title)) {
                                updateData.title = scraped.title;
                                updateData.artist = scraped.artist;
                            }
                            await song.update(updateData);
                            this.backfillProgress.updated++;
                        }
                        else {
                            this.backfillProgress.failed++;
                        }
                    }
                    catch (err) {
                        this.backfillProgress.failed++;
                        if (err instanceof scraper_service_1.RateLimitError) {
                            this.logger.warn('Rate limited during backfill — waiting 90s');
                            await new Promise((r) => setTimeout(r, 90000));
                        }
                        else {
                            this.logger.warn(`Backfill failed for ${song.url}: ${err.message}`);
                        }
                    }
                    processed++;
                    this.backfillProgress.processed = processed;
                    if (processed % 50 === 0) {
                        this.logger.log(`Backfill progress: ${processed}/${this.backfillProgress.total} (updated=${this.backfillProgress.updated}, failed=${this.backfillProgress.failed})`);
                        await new Promise((r) => setTimeout(r, 30000));
                    }
                }
            }
        }
        finally {
            this.backfillRunning = false;
        }
        const result = { ...this.backfillProgress, stopped: this.backfillShouldStop };
        this.logger.log(`Backfill complete: ${JSON.stringify(result)}`);
        return result;
    }
};
exports.CronService = CronService;
exports.CronService = CronService = CronService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, sequelize_1.InjectModel)(song_model_1.Song)),
    __metadata("design:paramtypes", [Object, scraper_service_1.ScraperService])
], CronService);
//# sourceMappingURL=cron.service.js.map