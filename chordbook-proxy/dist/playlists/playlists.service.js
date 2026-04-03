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
exports.PlaylistsService = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const playlist_model_1 = require("../database/playlist.model");
const playlist_song_model_1 = require("../database/playlist-song.model");
const song_model_1 = require("../database/song.model");
const crypto_1 = require("crypto");
let PlaylistsService = class PlaylistsService {
    playlistModel;
    playlistSongModel;
    constructor(playlistModel, playlistSongModel) {
        this.playlistModel = playlistModel;
        this.playlistSongModel = playlistSongModel;
    }
    async findAllByDevice(deviceId) {
        return this.playlistModel.findAll({
            where: { deviceId },
            include: [{ model: song_model_1.Song, through: { attributes: ['position'] } }],
            order: [['createdAt', 'DESC']],
        });
    }
    async findById(id, deviceId) {
        const playlist = await this.playlistModel.findByPk(id, {
            include: [{ model: song_model_1.Song, through: { attributes: ['position'] } }],
        });
        if (!playlist)
            throw new common_1.NotFoundException('Playlist not found');
        if (!playlist.isPublic && playlist.deviceId !== deviceId) {
            throw new common_1.ForbiddenException('Access denied');
        }
        return playlist;
    }
    async create(deviceId, title, description) {
        return this.playlistModel.create({ deviceId, title, description });
    }
    async update(id, deviceId, data) {
        const playlist = await this.findOwned(id, deviceId);
        if (data.isPublic && !playlist.shareCode) {
            data['shareCode'] = (0, crypto_1.randomBytes)(9).toString('base64url').slice(0, 12);
        }
        await playlist.update(data);
        return playlist;
    }
    async delete(id, deviceId) {
        const playlist = await this.findOwned(id, deviceId);
        await playlist.destroy();
    }
    async addSong(playlistId, songId, deviceId) {
        await this.findOwned(playlistId, deviceId);
        const maxPos = await this.playlistSongModel.max('position', {
            where: { playlistId },
        });
        await this.playlistSongModel.findOrCreate({
            where: { playlistId, songId },
            defaults: { playlistId, songId, position: (maxPos || 0) + 1 },
        });
    }
    async removeSong(playlistId, songId, deviceId) {
        await this.findOwned(playlistId, deviceId);
        await this.playlistSongModel.destroy({ where: { playlistId, songId } });
    }
    async reorderSongs(playlistId, songIds, deviceId) {
        await this.findOwned(playlistId, deviceId);
        for (let i = 0; i < songIds.length; i++) {
            await this.playlistSongModel.update({ position: i }, { where: { playlistId, songId: songIds[i] } });
        }
    }
    async findByShareCode(code) {
        const playlist = await this.playlistModel.findOne({
            where: { shareCode: code, isPublic: true },
            include: [{ model: song_model_1.Song, through: { attributes: ['position'] } }],
        });
        if (!playlist)
            throw new common_1.NotFoundException('Shared playlist not found');
        return playlist;
    }
    async findOwned(id, deviceId) {
        const playlist = await this.playlistModel.findByPk(id);
        if (!playlist)
            throw new common_1.NotFoundException('Playlist not found');
        if (playlist.deviceId !== deviceId)
            throw new common_1.ForbiddenException('Not your playlist');
        return playlist;
    }
};
exports.PlaylistsService = PlaylistsService;
exports.PlaylistsService = PlaylistsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, sequelize_1.InjectModel)(playlist_model_1.Playlist)),
    __param(1, (0, sequelize_1.InjectModel)(playlist_song_model_1.PlaylistSong)),
    __metadata("design:paramtypes", [Object, Object])
], PlaylistsService);
//# sourceMappingURL=playlists.service.js.map