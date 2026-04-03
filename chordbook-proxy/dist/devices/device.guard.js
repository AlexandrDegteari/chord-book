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
Object.defineProperty(exports, "__esModule", { value: true });
exports.CurrentDevice = exports.DeviceGuard = void 0;
const common_1 = require("@nestjs/common");
const devices_service_1 = require("./devices.service");
let DeviceGuard = class DeviceGuard {
    devicesService;
    constructor(devicesService) {
        this.devicesService = devicesService;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const deviceUuid = request.headers['x-device-uuid'];
        if (!deviceUuid) {
            throw new common_1.UnauthorizedException('X-Device-UUID header is required');
        }
        const device = await this.devicesService.findByUuid(deviceUuid);
        if (!device) {
            throw new common_1.UnauthorizedException('Unknown device. Call POST /api/devices/register first');
        }
        request.device = device;
        return true;
    }
};
exports.DeviceGuard = DeviceGuard;
exports.DeviceGuard = DeviceGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [devices_service_1.DevicesService])
], DeviceGuard);
exports.CurrentDevice = (0, common_1.createParamDecorator)((_data, ctx) => {
    return ctx.switchToHttp().getRequest().device;
});
//# sourceMappingURL=device.guard.js.map