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
exports.DevicesService = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const device_model_1 = require("../database/device.model");
let DevicesService = class DevicesService {
    deviceModel;
    constructor(deviceModel) {
        this.deviceModel = deviceModel;
    }
    async register(deviceUuid, nickname) {
        const [device] = await this.deviceModel.findOrCreate({
            where: { deviceUuid },
            defaults: { deviceUuid, nickname: nickname || null },
        });
        return device;
    }
    async findByUuid(deviceUuid) {
        return this.deviceModel.findOne({ where: { deviceUuid } });
    }
    async findAll() {
        return this.deviceModel.findAll({ order: [['createdAt', 'DESC']] });
    }
};
exports.DevicesService = DevicesService;
exports.DevicesService = DevicesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, sequelize_1.InjectModel)(device_model_1.Device)),
    __metadata("design:paramtypes", [Object])
], DevicesService);
//# sourceMappingURL=devices.service.js.map