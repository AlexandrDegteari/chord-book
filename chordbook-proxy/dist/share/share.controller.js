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
exports.ShareController = void 0;
const common_1 = require("@nestjs/common");
const playlists_service_1 = require("../playlists/playlists.service");
const user_songs_service_1 = require("../user-songs/user-songs.service");
let ShareController = class ShareController {
    playlistsService;
    userSongsService;
    constructor(playlistsService, userSongsService) {
        this.playlistsService = playlistsService;
        this.userSongsService = userSongsService;
    }
    async getSharedPlaylist(code) {
        return this.playlistsService.findByShareCode(code);
    }
    async getSharedSong(code) {
        return this.userSongsService.findByShareCode(code);
    }
};
exports.ShareController = ShareController;
__decorate([
    (0, common_1.Get)('playlist/:code'),
    __param(0, (0, common_1.Param)('code')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ShareController.prototype, "getSharedPlaylist", null);
__decorate([
    (0, common_1.Get)('song/:code'),
    __param(0, (0, common_1.Param)('code')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ShareController.prototype, "getSharedSong", null);
exports.ShareController = ShareController = __decorate([
    (0, common_1.Controller)('api/share'),
    __metadata("design:paramtypes", [playlists_service_1.PlaylistsService,
        user_songs_service_1.UserSongsService])
], ShareController);
//# sourceMappingURL=share.controller.js.map