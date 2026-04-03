"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DatabaseModule = void 0;
const common_1 = require("@nestjs/common");
const sequelize_1 = require("@nestjs/sequelize");
const config_1 = require("@nestjs/config");
const song_model_1 = require("./song.model");
const device_model_1 = require("./device.model");
const playlist_model_1 = require("./playlist.model");
const playlist_song_model_1 = require("./playlist-song.model");
const user_song_model_1 = require("./user-song.model");
let DatabaseModule = class DatabaseModule {
};
exports.DatabaseModule = DatabaseModule;
exports.DatabaseModule = DatabaseModule = __decorate([
    (0, common_1.Module)({
        imports: [
            sequelize_1.SequelizeModule.forRootAsync({
                imports: [config_1.ConfigModule],
                inject: [config_1.ConfigService],
                useFactory: (config) => ({
                    dialect: 'postgres',
                    host: config.get('DATABASE_HOST', 'localhost'),
                    port: config.get('DATABASE_PORT', 5432),
                    username: config.get('DATABASE_USER', 'sixstrings'),
                    password: config.get('DATABASE_PASSWORD', ''),
                    database: config.get('DATABASE_NAME', 'sixstrings_db'),
                    models: [song_model_1.Song, device_model_1.Device, playlist_model_1.Playlist, playlist_song_model_1.PlaylistSong, user_song_model_1.UserSong],
                    autoLoadModels: true,
                    synchronize: true,
                    logging: false,
                }),
            }),
        ],
    })
], DatabaseModule);
//# sourceMappingURL=database.module.js.map