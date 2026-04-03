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
exports.UserSongsController = void 0;
const common_1 = require("@nestjs/common");
const user_songs_service_1 = require("./user-songs.service");
const device_guard_1 = require("../devices/device.guard");
const device_model_1 = require("../database/device.model");
let UserSongsController = class UserSongsController {
    userSongsService;
    constructor(userSongsService) {
        this.userSongsService = userSongsService;
    }
    async findAll(device) {
        return this.userSongsService.findAllByDevice(device.id);
    }
    async create(device, body) {
        return this.userSongsService.create(device.id, body);
    }
    async findOne(id, device) {
        return this.userSongsService.findById(id, device.id);
    }
    async update(id, device, body) {
        return this.userSongsService.update(id, device.id, body);
    }
    async remove(id, device) {
        await this.userSongsService.delete(id, device.id);
        return { deleted: true };
    }
    async submit(id, device) {
        return this.userSongsService.submit(id, device.id);
    }
};
exports.UserSongsController = UserSongsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [device_model_1.Device]),
    __metadata("design:returntype", Promise)
], UserSongsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, device_guard_1.CurrentDevice)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [device_model_1.Device, Object]),
    __metadata("design:returntype", Promise)
], UserSongsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device]),
    __metadata("design:returntype", Promise)
], UserSongsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Put)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device, Object]),
    __metadata("design:returntype", Promise)
], UserSongsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device]),
    __metadata("design:returntype", Promise)
], UserSongsController.prototype, "remove", null);
__decorate([
    (0, common_1.Post)(':id/submit'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, device_guard_1.CurrentDevice)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, device_model_1.Device]),
    __metadata("design:returntype", Promise)
], UserSongsController.prototype, "submit", null);
exports.UserSongsController = UserSongsController = __decorate([
    (0, common_1.Controller)('api/user-songs'),
    (0, common_1.UseGuards)(device_guard_1.DeviceGuard),
    __metadata("design:paramtypes", [user_songs_service_1.UserSongsService])
], UserSongsController);
//# sourceMappingURL=user-songs.controller.js.map