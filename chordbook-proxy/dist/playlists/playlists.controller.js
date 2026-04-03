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
exports.PlaylistsController = void 0;
const common_1 = require("@nestjs/common");
const playlists_service_1 = require("./playlists.service");
const device_guard_1 = require("../devices/device.guard");
const device_model_1 = require("../database/device.model");
let PlaylistsController = class PlaylistsController {
    playlistsService;
    constructor(playlistsService) {
        this.playlistsService = playlistsService;
    }
    async findAll(device) {
        return this.playlistsService.findAllByDevice(device.id);
    }
    async create(device, body) {
        return this.playlistsService.create(device.id, body.title, body.description);
    }
    async findOne(id, device) {
        return this.playlistsService.findById(id, device.id);
    }
    async update(id, device, body) {
        return this.playlistsService.update(id, device.id, body);
    }
    async remove(id, device) {
        await this.playlistsService.delete(id, device.id);
        return { deleted: true };
    }
    async addSong(id, device, body) {
        await this.playlistsService.addSong(id, body.songId, device.id);
        return { added: true };
    }
    async removeSong(id, songId, device) {
        await this.playlistsService.removeSong(id, songId, device.id);
        return { removed: true };
    }
    async reorder(id, device, body) {
        await this.playlistsService.reorderSongs(id, body.songIds, device.id);
        return { reordered: true };
    }
};
exports.PlaylistsController = PlaylistsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [device_model_1.Device]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, device_guard_1.CurrentDevice)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [device_model_1.Device, Object]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device, Object]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "remove", null);
__decorate([
    (0, common_1.Post)(':id/songs'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device, Object]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "addSong", null);
__decorate([
    (0, common_1.Delete)(':id/songs/:songId'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('songId')),
    __param(2, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, device_model_1.Device]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "removeSong", null);
__decorate([
    (0, common_1.Patch)(':id/songs/reorder'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device, Object]),
    __metadata("design:returntype", Promise)
], PlaylistsController.prototype, "reorder", null);
exports.PlaylistsController = PlaylistsController = __decorate([
    (0, common_1.Controller)('api/playlists'),
    (0, common_1.UseGuards)(device_guard_1.DeviceGuard),
    __metadata("design:paramtypes", [playlists_service_1.PlaylistsService])
], PlaylistsController);
//# sourceMappingURL=playlists.controller.js.map