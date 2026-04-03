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
exports.PlaylistSong = void 0;
const sequelize_typescript_1 = require("sequelize-typescript");
const playlist_model_1 = require("./playlist.model");
const song_model_1 = require("./song.model");
let PlaylistSong = class PlaylistSong extends sequelize_typescript_1.Model {
};
exports.PlaylistSong = PlaylistSong;
__decorate([
    (0, sequelize_typescript_1.Column)({
        type: sequelize_typescript_1.DataType.UUID,
        defaultValue: sequelize_typescript_1.DataType.UUIDV4,
        primaryKey: true,
    }),
    __metadata("design:type", String)
], PlaylistSong.prototype, "id", void 0);
__decorate([
    (0, sequelize_typescript_1.ForeignKey)(() => playlist_model_1.Playlist),
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.UUID, allowNull: false }),
    __metadata("design:type", String)
], PlaylistSong.prototype, "playlistId", void 0);
__decorate([
    (0, sequelize_typescript_1.ForeignKey)(() => song_model_1.Song),
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.UUID, allowNull: false }),
    __metadata("design:type", String)
], PlaylistSong.prototype, "songId", void 0);
__decorate([
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.INTEGER, defaultValue: 0 }),
    __metadata("design:type", Number)
], PlaylistSong.prototype, "position", void 0);
__decorate([
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.DATE, defaultValue: sequelize_typescript_1.DataType.NOW }),
    __metadata("design:type", Date)
], PlaylistSong.prototype, "addedAt", void 0);
exports.PlaylistSong = PlaylistSong = __decorate([
    (0, sequelize_typescript_1.Table)({ tableName: 'playlist_songs', timestamps: false })
], PlaylistSong);
//# sourceMappingURL=playlist-song.model.js.map