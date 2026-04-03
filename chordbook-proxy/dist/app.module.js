"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const path_1 = require("path");
const database_module_1 = require("./database/database.module");
const scraper_module_1 = require("./scraper/scraper.module");
const songs_module_1 = require("./songs/songs.module");
const devices_module_1 = require("./devices/devices.module");
const playlists_module_1 = require("./playlists/playlists.module");
const user_songs_module_1 = require("./user-songs/user-songs.module");
const share_module_1 = require("./share/share.module");
const admin_module_1 = require("./admin/admin.module");
const cron_module_1 = require("./cron/cron.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: (0, path_1.join)(__dirname, '..', '.env'),
            }),
            database_module_1.DatabaseModule,
            scraper_module_1.ScraperModule,
            songs_module_1.SongsModule,
            devices_module_1.DevicesModule,
            playlists_module_1.PlaylistsModule,
            user_songs_module_1.UserSongsModule,
            share_module_1.ShareModule,
            admin_module_1.AdminModule,
            cron_module_1.CronModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map