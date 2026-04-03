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
exports.UserSongsService = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const user_song_model_1 = require("../database/user-song.model");
const song_model_1 = require("../database/song.model");
const crypto_1 = require("crypto");
let UserSongsService = class UserSongsService {
    userSongModel;
    songModel;
    constructor(userSongModel, songModel) {
        this.userSongModel = userSongModel;
        this.songModel = songModel;
    }
    async findAllByDevice(deviceId) {
        return this.userSongModel.findAll({
            where: { deviceId },
            order: [['createdAt', 'DESC']],
        });
    }
    async findById(id, deviceId) {
        const song = await this.userSongModel.findByPk(id);
        if (!song)
            throw new common_1.NotFoundException('User song not found');
        if (!song.isPublic && song.deviceId !== deviceId) {
            throw new common_1.ForbiddenException('Access denied');
        }
        return song;
    }
    async create(deviceId, data) {
        return this.userSongModel.create({
            deviceId,
            title: data.title,
            artist: data.artist,
            sections: data.sections,
            originalSongId: data.originalSongId || null,
        });
    }
    async update(id, deviceId, data) {
        const song = await this.findOwned(id, deviceId);
        if (data.isPublic && !song.shareCode) {
            data['shareCode'] = (0, crypto_1.randomBytes)(9).toString('base64url').slice(0, 12);
        }
        await song.update(data);
        return song;
    }
    async delete(id, deviceId) {
        const song = await this.findOwned(id, deviceId);
        await song.destroy();
    }
    async submit(id, deviceId) {
        const song = await this.findOwned(id, deviceId);
        if (song.status !== 'draft' && song.status !== 'rejected') {
            throw new common_1.ForbiddenException('Can only submit drafts or rejected songs');
        }
        await song.update({ status: 'submitted' });
        return song;
    }
    async findByShareCode(code) {
        const song = await this.userSongModel.findOne({
            where: { shareCode: code, isPublic: true },
        });
        if (!song)
            throw new common_1.NotFoundException('Shared song not found');
        return song;
    }
    async findPending() {
        return this.userSongModel.findAll({
            where: { status: 'submitted' },
            order: [['createdAt', 'ASC']],
        });
    }
    async approve(id) {
        const userSong = await this.userSongModel.findByPk(id);
        if (!userSong)
            throw new common_1.NotFoundException('Song not found');
        await this.songModel.create({
            title: userSong.title,
            artist: userSong.artist,
            sections: userSong.sections,
            source: 'user',
            status: 'active',
            submittedBy: userSong.deviceId,
        });
        await userSong.update({ status: 'approved' });
        return userSong;
    }
    async reject(id, reason) {
        const userSong = await this.userSongModel.findByPk(id);
        if (!userSong)
            throw new common_1.NotFoundException('Song not found');
        await userSong.update({ status: 'rejected', adminNotes: reason });
        return userSong;
    }
    async findOwned(id, deviceId) {
        const song = await this.userSongModel.findByPk(id);
        if (!song)
            throw new common_1.NotFoundException('User song not found');
        if (song.deviceId !== deviceId)
            throw new common_1.ForbiddenException('Not your song');
        return song;
    }
};
exports.UserSongsService = UserSongsService;
exports.UserSongsService = UserSongsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, sequelize_1.InjectModel)(user_song_model_1.UserSong)),
    __param(1, (0, sequelize_1.InjectModel)(song_model_1.Song)),
    __metadata("design:paramtypes", [Object, Object])
], UserSongsService);
//# sourceMappingURL=user-songs.service.js.map