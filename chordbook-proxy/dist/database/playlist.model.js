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
exports.Playlist = void 0;
const sequelize_typescript_1 = require("sequelize-typescript");
const device_model_1 = require("./device.model");
const song_model_1 = require("./song.model");
const playlist_song_model_1 = require("./playlist-song.model");
let Playlist = class Playlist extends sequelize_typescript_1.Model {
};
exports.Playlist = Playlist;
__decorate([
    (0, sequelize_typescript_1.Column)({
        type: sequelize_typescript_1.DataType.UUID,
        defaultValue: sequelize_typescript_1.DataType.UUIDV4,
        primaryKey: true,
    }),
    __metadata("design:type", String)
], Playlist.prototype, "id", void 0);
__decorate([
    (0, sequelize_typescript_1.ForeignKey)(() => device_model_1.Device),
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.UUID, allowNull: false }),
    __metadata("design:type", String)
], Playlist.prototype, "deviceId", void 0);
__decorate([
    (0, sequelize_typescript_1.BelongsTo)(() => device_model_1.Device),
    __metadata("design:type", device_model_1.Device)
], Playlist.prototype, "device", void 0);
__decorate([
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.STRING(255), allowNull: false }),
    __metadata("design:type", String)
], Playlist.prototype, "title", void 0);
__decorate([
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.TEXT, allowNull: true }),
    __metadata("design:type", Object)
], Playlist.prototype, "description", void 0);
__decorate([
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.BOOLEAN, defaultValue: false }),
    __metadata("design:type", Boolean)
], Playlist.prototype, "isPublic", void 0);
__decorate([
    (0, sequelize_typescript_1.Index)({ unique: true }),
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.STRING(12), allowNull: true, unique: true }),
    __metadata("design:type", Object)
], Playlist.prototype, "shareCode", void 0);
__decorate([
    (0, sequelize_typescript_1.BelongsToMany)(() => song_model_1.Song, () => playlist_song_model_1.PlaylistSong),
    __metadata("design:type", Array)
], Playlist.prototype, "songs", void 0);
__decorate([
    sequelize_typescript_1.CreatedAt,
    __metadata("design:type", Date)
], Playlist.prototype, "createdAt", void 0);
__decorate([
    sequelize_typescript_1.UpdatedAt,
    __metadata("design:type", Date)
], Playlist.prototype, "updatedAt", void 0);
exports.Playlist = Playlist = __decorate([
    (0, sequelize_typescript_1.Table)({ tableName: 'playlists', timestamps: true })
], Playlist);
//# sourceMappingURL=playlist.model.js.map