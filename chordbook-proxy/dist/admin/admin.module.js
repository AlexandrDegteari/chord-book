"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminModule = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const config_1 = require("@nestjs/config");
const admin_controller_1 = require("./admin.controller");
const admin_guard_1 = require("./admin.guard");
const user_songs_module_1 = require("../user-songs/user-songs.module");
const devices_module_1 = require("../devices/devices.module");
const songs_module_1 = require("../songs/songs.module");
const cron_module_1 = require("../cron/cron.module");
const song_model_1 = require("../database/song.model");
const device_model_1 = require("../database/device.model");
const user_song_model_1 = require("../database/user-song.model");
const playlist_model_1 = require("../database/playlist.model");
let AdminModule = class AdminModule {
};
exports.AdminModule = AdminModule;
exports.AdminModule = AdminModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule,
            sequelize_1.SequelizeModule.forFeature([song_model_1.Song, device_model_1.Device, user_song_model_1.UserSong, playlist_model_1.Playlist]),
            user_songs_module_1.UserSongsModule,
            devices_module_1.DevicesModule,
            songs_module_1.SongsModule,
            cron_module_1.CronModule,
        ],
        controllers: [admin_controller_1.AdminController],
        providers: [admin_guard_1.AdminGuard],
    })
], AdminModule);
//# sourceMappingURL=admin.module.js.map