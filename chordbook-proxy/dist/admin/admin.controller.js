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
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminController = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("sequelize");
const admin_guard_1 = require("./admin.guard");
const user_songs_service_1 = require("../user-songs/user-songs.service");
const devices_service_1 = require("../devices/devices.service");
const cron_service_1 = require("../cron/cron.service");
const sequelize_2 = require("@nestjs/sequelize");
const song_model_1 = require("../database/song.model");
const device_model_1 = require("../database/device.model");
const user_song_model_1 = require("../database/user-song.model");
const playlist_model_1 = require("../database/playlist.model");
let AdminController = class AdminController {
    userSongsService;
    devicesService;
    cronService;
    songModel;
    deviceModel;
    userSongModel;
    playlistModel;
    constructor(userSongsService, devicesService, cronService, songModel, deviceModel, userSongModel, playlistModel) {
        this.userSongsService = userSongsService;
        this.devicesService = devicesService;
        this.cronService = cronService;
        this.songModel = songModel;
        this.deviceModel = deviceModel;
        this.userSongModel = userSongModel;
        this.playlistModel = playlistModel;
    }
    async getStats() {
        const [songs, devices, playlists, pendingSongs, pendingImport, lastSyncResult] = await Promise.all([
            this.songModel.count({ where: { status: 'active' } }),
            this.deviceModel.count(),
            this.playlistModel.count(),
            this.userSongModel.count({ where: { status: 'submitted' } }),
            this.songModel.count({ where: { status: 'pending', source: 'scraped' } }),
            this.songModel.max('scrapedAt'),
        ]);
        return {
            songs,
            devices,
            playlists,
            pendingSongs,
            pendingImport,
            lastSync: lastSyncResult || null,
            scrapeStatus: this.cronService.getStatus(),
        };
    }
    async getPendingSongs() {
        return this.userSongsService.findPending();
    }
    async getPendingSong(id) {
        return this.userSongsService.findById(id);
    }
    async approveSong(id) {
        return this.userSongsService.approve(id);
    }
    async rejectSong(id, body) {
        return this.userSongsService.reject(id, body.reason);
    }
    async getDevices() {
        return this.devicesService.findAll();
    }
    async getSongDetail(id) {
        return this.songModel.findByPk(id);
    }
    async getSongs(page = '1', limit = '50', letter, search) {
        const pageNum = Math.max(1, parseInt(page) || 1);
        const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 50));
        const offset = (pageNum - 1) * limitNum;
        const where = {};
        if (letter === 'ALL_RU') {
            where.artist = { [sequelize_1.Op.regexp]: '^[А-Яа-яЁё]' };
        }
        else if (letter) {
            where.artist = { [sequelize_1.Op.iLike]: `${letter}%` };
        }
        if (search) {
            const conditions = [
                { title: { [sequelize_1.Op.iLike]: `%${search}%` } },
                { artist: { [sequelize_1.Op.iLike]: `%${search}%` } },
            ];
            if (/[а-яё]/i.test(search)) {
                const map = {
                    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'zh',
                    'з': 'z', 'и': 'i', 'й': 'j', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o',
                    'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c',
                    'ч': 'ch', 'ш': 'sh', 'щ': 'sch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
                };
                const translit = search.toLowerCase().split('').map(c => map[c] ?? c).join('');
                conditions.push({ title: { [sequelize_1.Op.iLike]: `%${translit}%` } }, { artist: { [sequelize_1.Op.iLike]: `%${translit}%` } });
            }
            where[sequelize_1.Op.or] = conditions;
        }
        const { count, rows } = await this.songModel.findAndCountAll({
            where,
            order: letter ? [['artist', 'ASC'], ['title', 'ASC']] : [['title', 'ASC']],
            limit: limitNum,
            offset,
            attributes: { exclude: ['sections'] },
        });
        return {
            songs: rows,
            total: count,
            page: pageNum,
            totalPages: Math.ceil(count / limitNum),
        };
    }
    async fullScrape() {
        const status = this.cronService.getStatus();
        if (status.isRunning) {
            return { error: 'Scrape already running' };
        }
        this.cronService.fullScrape();
        return { message: 'Full scrape started in background. Check server logs for progress.' };
    }
    async cronStatus() {
        return this.cronService.getStatus();
    }
    async backfillSections(limit, artist) {
        const status = this.cronService.getBackfillStatus();
        if (status.running) {
            return { error: 'Backfill already running' };
        }
        const limitNum = parseInt(limit || '5000') || 5000;
        this.cronService.backfillSections(limitNum, artist);
        return { message: `Backfill started (limit=${limitNum}${artist ? `, artist="${artist}"` : ''}). Check status at /api/admin/cron/backfill-status` };
    }
    async backfillStatus() {
        return this.cronService.getBackfillStatus();
    }
    async backfillStop() {
        return this.cronService.stopBackfill();
    }
    async bulkImport(body) {
        if (!body.songs || !Array.isArray(body.songs)) {
            return { error: 'songs array required' };
        }
        let imported = 0;
        let skipped = 0;
        for (const song of body.songs) {
            try {
                const exists = await this.songModel.findOne({ where: { externalId: song.id } });
                if (!exists) {
                    await this.songModel.create({
                        externalId: song.id,
                        title: song.title,
                        artist: song.artist,
                        url: song.url,
                        sections: [],
                        source: 'scraped',
                        status: 'pending',
                        scrapedAt: new Date(),
                    });
                    imported++;
                }
                else {
                    skipped++;
                }
            }
            catch {
                skipped++;
            }
        }
        return { imported, skipped, total: body.songs.length };
    }
    async getImportQueue(page = '1', limit = '50', search) {
        const pageNum = Math.max(1, parseInt(page) || 1);
        const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 50));
        const offset = (pageNum - 1) * limitNum;
        const where = { status: 'pending', source: 'scraped' };
        if (search) {
            where[sequelize_1.Op.or] = [
                { title: { [sequelize_1.Op.iLike]: `%${search}%` } },
                { artist: { [sequelize_1.Op.iLike]: `%${search}%` } },
            ];
        }
        const { count, rows } = await this.songModel.findAndCountAll({
            where,
            order: [['artist', 'ASC'], ['title', 'ASC']],
            limit: limitNum,
            offset,
            attributes: { exclude: ['sections'] },
        });
        return {
            songs: rows,
            total: count,
            page: pageNum,
            totalPages: Math.ceil(count / limitNum),
        };
    }
    async approveImport(body) {
        if (!body.songIds?.length)
            return { error: 'songIds required' };
        const [count] = await this.songModel.update({ status: 'active' }, { where: { id: body.songIds, status: 'pending' } });
        return { approved: count };
    }
    async approveAllImport() {
        const [count] = await this.songModel.update({ status: 'active' }, { where: { status: 'pending', source: 'scraped' } });
        return { approved: count };
    }
    async rejectImport(body) {
        if (!body.songIds?.length)
            return { error: 'songIds required' };
        await this.songModel.destroy({
            where: { id: body.songIds, status: 'pending' },
        });
        return { deleted: body.songIds.length };
    }
    async saveNamesFile(body) {
        if (!body.songs?.length)
            return { error: 'no songs' };
        const fs = require('fs');
        const path = require('path');
        const filePath = path.join(__dirname, '..', '..', 'real_names.json');
        fs.writeFileSync(filePath, JSON.stringify(body.songs));
        return { saved: body.songs.length, path: filePath };
    }
    async cleanupEmptySongs() {
        const sequelize = this.songModel.sequelize;
        const emptyCond = "(sections IS NULL OR sections::text = '[]' OR sections::text = 'null')";
        const [[{ count }]] = await sequelize.query(`SELECT COUNT(*) as count FROM songs WHERE ${emptyCond}`);
        if (parseInt(count) === 0) {
            return { deleted: 0, playlistSongsRemoved: 0, userSongsUnlinked: 0 };
        }
        const [, psResult] = await sequelize.query(`DELETE FROM playlist_songs WHERE "songId" IN (SELECT id FROM songs WHERE ${emptyCond})`);
        const playlistSongsRemoved = psResult?.rowCount || 0;
        const [, usResult] = await sequelize.query(`UPDATE user_songs SET "originalSongId" = NULL WHERE "originalSongId" IN (SELECT id FROM songs WHERE ${emptyCond})`);
        const userSongsUnlinked = usResult?.rowCount || 0;
        const [, delResult] = await sequelize.query(`DELETE FROM songs WHERE ${emptyCond}`);
        const deleted = delResult?.rowCount || 0;
        return { deleted, playlistSongsRemoved, userSongsUnlinked };
    }
    async bulkUpdateNames(body) {
        if (!body.songs || !Array.isArray(body.songs)) {
            return { error: 'songs array required' };
        }
        const sequelize = this.songModel.sequelize;
        let updated = 0;
        for (let i = 0; i < body.songs.length; i += 100) {
            const chunk = body.songs.slice(i, i + 100);
            const cases_title = [];
            const cases_artist = [];
            const ids = [];
            for (const s of chunk) {
                const escapedTitle = s.title.replace(/'/g, "''");
                const escapedArtist = s.artist.replace(/'/g, "''");
                cases_title.push(`WHEN "externalId" = '${s.id}' THEN '${escapedTitle}'`);
                cases_artist.push(`WHEN "externalId" = '${s.id}' THEN '${escapedArtist}'`);
                ids.push(`'${s.id}'`);
            }
            try {
                const [, result] = await sequelize.query(`
          UPDATE songs SET
            title = CASE ${cases_title.join(' ')} ELSE title END,
            artist = CASE ${cases_artist.join(' ')} ELSE artist END,
            "updatedAt" = NOW()
          WHERE "externalId" IN (${ids.join(',')})
        `);
                updated += result?.rowCount || chunk.length;
            }
            catch (e) {
            }
        }
        return { updated, total: body.songs.length };
    }
};
exports.AdminController = AdminController;
__decorate([
    (0, common_1.Get)('stats'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getStats", null);
__decorate([
    (0, common_1.Get)('pending-songs'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getPendingSongs", null);
__decorate([
    (0, common_1.Get)('pending-songs/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getPendingSong", null);
__decorate([
    (0, common_1.Post)('pending-songs/:id/approve'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "approveSong", null);
__decorate([
    (0, common_1.Post)('pending-songs/:id/reject'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "rejectSong", null);
__decorate([
    (0, common_1.Get)('devices'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getDevices", null);
__decorate([
    (0, common_1.Get)('song/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getSongDetail", null);
__decorate([
    (0, common_1.Get)('songs'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('letter')),
    __param(3, (0, common_1.Query)('search')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getSongs", null);
__decorate([
    (0, common_1.Post)('cron/full-scrape'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "fullScrape", null);
__decorate([
    (0, common_1.Get)('cron/status'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "cronStatus", null);
__decorate([
    (0, common_1.Post)('cron/backfill-sections'),
    __param(0, (0, common_1.Query)('limit')),
    __param(1, (0, common_1.Query)('artist')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "backfillSections", null);
__decorate([
    (0, common_1.Get)('cron/backfill-status'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "backfillStatus", null);
__decorate([
    (0, common_1.Post)('cron/backfill-stop'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "backfillStop", null);
__decorate([
    (0, common_1.Post)('bulk-import'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "bulkImport", null);
__decorate([
    (0, common_1.Get)('import-queue'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('search')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getImportQueue", null);
__decorate([
    (0, common_1.Post)('import-queue/approve'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "approveImport", null);
__decorate([
    (0, common_1.Post)('import-queue/approve-all'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "approveAllImport", null);
__decorate([
    (0, common_1.Post)('import-queue/reject'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "rejectImport", null);
__decorate([
    (0, common_1.Post)('save-names-file'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "saveNamesFile", null);
__decorate([
    (0, common_1.Post)('cleanup-empty-songs'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "cleanupEmptySongs", null);
__decorate([
    (0, common_1.Post)('bulk-update-names'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "bulkUpdateNames", null);
exports.AdminController = AdminController = __decorate([
    (0, common_1.Controller)('api/admin'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(3, (0, sequelize_2.InjectModel)(song_model_1.Song)),
    __param(4, (0, sequelize_2.InjectModel)(device_model_1.Device)),
    __param(5, (0, sequelize_2.InjectModel)(user_song_model_1.UserSong)),
    __param(6, (0, sequelize_2.InjectModel)(playlist_model_1.Playlist)),
    __metadata("design:paramtypes", [user_songs_service_1.UserSongsService,
        devices_service_1.DevicesService,
        cron_service_1.CronService, Object, Object, Object, Object])
], AdminController);
//# sourceMappingURL=admin.controller.js.map