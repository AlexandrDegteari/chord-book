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
const schedule_1 = require("@nestjs/schedule");
const sequelize_1 = require("@nestjs/sequelize");
const song_model_1 = require("../database/song.model");
const scraper_service_1 = require("../scraper/scraper.service");
let CronService = CronService_1 = class CronService {
    songModel;
    scraperService;
    logger = new common_1.Logger(CronService_1.name);
    isRunning = false;
    constructor(songModel, scraperService) {
        this.songModel = songModel;
        this.scraperService = scraperService;
    }
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
                        }
                        catch (err) {
                            this.logger.warn(`Failed to scrape ${result.url}: ${err.message}`);
                        }
                        await new Promise((r) => setTimeout(r, 2000));
                    }
                }
                await new Promise((r) => setTimeout(r, 1000));
            }
            catch (err) {
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
                            if (exists) {
                                await exists.update({
                                    title: fullSong.title,
                                    artist: fullSong.artist,
                                    url: fullSong.url,
                                    sections: fullSong.sections,
                                    scrapedAt: new Date(),
                                });
                            }
                            else {
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
                        }
                        catch (err) {
                            failed++;
                            this.logger.warn(`Failed: ${song.url} - ${err.message}`);
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
};
exports.CronService = CronService;
__decorate([
    (0, schedule_1.Cron)('0 3 * * 0'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CronService.prototype, "weeklySync", null);
exports.CronService = CronService = CronService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, sequelize_1.InjectModel)(song_model_1.Song)),
    __metadata("design:paramtypes", [Object, scraper_service_1.ScraperService])
], CronService);
//# sourceMappingURL=cron.service.js.map