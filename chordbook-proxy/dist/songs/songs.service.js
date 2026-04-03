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
var SongsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SongsService = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const sequelize_2 = require("sequelize");
const song_model_1 = require("../database/song.model");
const scraper_service_1 = require("../scraper/scraper.service");
let SongsService = SongsService_1 = class SongsService {
    songModel;
    scraperService;
    logger = new common_1.Logger(SongsService_1.name);
    constructor(songModel, scraperService) {
        this.songModel = songModel;
        this.scraperService = scraperService;
    }
    transliterate(text) {
        const map = {
            'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'zh',
            'з': 'z', 'и': 'i', 'й': 'j', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o',
            'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c',
            'ч': 'ch', 'ш': 'sh', 'щ': 'sch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
        };
        return text.toLowerCase().split('').map(c => map[c] ?? c).join('');
    }
    isCyrillic(text) {
        return /[а-яё]/i.test(text);
    }
    async search(query) {
        const searchConditions = [
            { title: { [sequelize_2.Op.iLike]: `%${query}%` } },
            { artist: { [sequelize_2.Op.iLike]: `%${query}%` } },
        ];
        if (this.isCyrillic(query)) {
            const translit = this.transliterate(query);
            searchConditions.push({ title: { [sequelize_2.Op.iLike]: `%${translit}%` } }, { artist: { [sequelize_2.Op.iLike]: `%${translit}%` } });
        }
        const dbResults = await this.songModel.findAll({
            where: {
                status: 'active',
                [sequelize_2.Op.or]: searchConditions,
            },
            limit: 50,
            order: [
                [this.songModel.sequelize.literal(`CASE WHEN artist ILIKE '%${query.replace(/'/g, "''")}%' THEN 0 ELSE 1 END`), 'ASC'],
                ['artist', 'ASC'],
                ['title', 'ASC'],
            ],
        });
        const formatted = dbResults.map((s) => ({
            id: s.externalId || s.id,
            title: s.title,
            artist: s.artist,
            url: s.url || '',
        }));
        try {
            const scraped = await this.scraperService.search(query);
            this.saveSongsInBackground(scraped);
            const dbIds = new Set(formatted.map((r) => r.id));
            for (const s of scraped) {
                if (!dbIds.has(s.id)) {
                    formatted.push(s);
                }
            }
        }
        catch (err) {
            this.logger.warn(`Scraper search failed (returning DB results only): ${err.message}`);
        }
        return formatted;
    }
    async getSong(id) {
        const dbSong = await this.songModel.findOne({
            where: { externalId: id, status: 'active' },
        });
        if (dbSong && this.hasSections(dbSong)) {
            return this.formatSong(dbSong);
        }
        const dbSongById = await this.songModel.findOne({
            where: { id, status: 'active' },
        });
        if (dbSongById && this.hasSections(dbSongById)) {
            return this.formatSong(dbSongById);
        }
        try {
            const scraped = await this.scraperService.getSong(id);
            await this.upsertFromScraped(scraped);
            return scraped;
        }
        catch (err) {
            this.logger.warn(`Scraper getSong failed: ${err.message}`);
            const fallback = dbSong || dbSongById;
            if (fallback)
                return this.formatSong(fallback);
            throw err;
        }
    }
    async getSongByUrl(url) {
        const dbSong = await this.songModel.findOne({
            where: { url, status: 'active' },
        });
        if (dbSong && this.hasSections(dbSong)) {
            return this.formatSong(dbSong);
        }
        const idMatch = url.match(/\/(\d+)-/);
        let dbSongByExtId = null;
        if (idMatch) {
            dbSongByExtId = await this.songModel.findOne({
                where: { externalId: idMatch[1], status: 'active' },
            });
            if (dbSongByExtId && this.hasSections(dbSongByExtId)) {
                return this.formatSong(dbSongByExtId);
            }
        }
        try {
            const scraped = await this.scraperService.getSongByUrl(url);
            await this.upsertFromScraped(scraped);
            return scraped;
        }
        catch (err) {
            this.logger.warn(`Scraper getSongByUrl failed: ${err.message}`);
            const fallback = dbSong || dbSongByExtId;
            if (fallback)
                return this.formatSong(fallback);
            throw err;
        }
    }
    async upsertFromScraped(scraped) {
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
        }
        catch (err) {
            this.logger.error('Failed to upsert song', err);
            return null;
        }
    }
    async findById(id) {
        return this.songModel.findByPk(id);
    }
    hasSections(dbSong) {
        return Array.isArray(dbSong.sections) && dbSong.sections.length > 0;
    }
    formatSong(dbSong) {
        return {
            id: dbSong.externalId || dbSong.id,
            title: dbSong.title,
            artist: dbSong.artist,
            url: dbSong.url || '',
            sections: dbSong.sections,
        };
    }
    async saveSongsInBackground(results) {
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
            }
            catch {
            }
        }
    }
};
exports.SongsService = SongsService;
exports.SongsService = SongsService = SongsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, sequelize_1.InjectModel)(song_model_1.Song)),
    __metadata("design:paramtypes", [Object, scraper_service_1.ScraperService])
], SongsService);
//# sourceMappingURL=songs.service.js.map