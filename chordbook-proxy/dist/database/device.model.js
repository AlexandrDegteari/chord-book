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
exports.Device = void 0;
const sequelize_typescript_1 = require("sequelize-typescript");
const playlist_model_1 = require("./playlist.model");
const user_song_model_1 = require("./user-song.model");
let Device = class Device extends sequelize_typescript_1.Model {
};
exports.Device = Device;
__decorate([
    (0, sequelize_typescript_1.Column)({
        type: sequelize_typescript_1.DataType.UUID,
        defaultValue: sequelize_typescript_1.DataType.UUIDV4,
        primaryKey: true,
    }),
    __metadata("design:type", String)
], Device.prototype, "id", void 0);
__decorate([
    (0, sequelize_typescript_1.Index)({ unique: true }),
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.STRING(255), allowNull: false, unique: true }),
    __metadata("design:type", String)
], Device.prototype, "deviceUuid", void 0);
__decorate([
    (0, sequelize_typescript_1.Column)({ type: sequelize_typescript_1.DataType.STRING(100), allowNull: true }),
    __metadata("design:type", Object)
], Device.prototype, "nickname", void 0);
__decorate([
    (0, sequelize_typescript_1.HasMany)(() => playlist_model_1.Playlist),
    __metadata("design:type", Array)
], Device.prototype, "playlists", void 0);
__decorate([
    (0, sequelize_typescript_1.HasMany)(() => user_song_model_1.UserSong),
    __metadata("design:type", Array)
], Device.prototype, "userSongs", void 0);
__decorate([
    sequelize_typescript_1.CreatedAt,
    __metadata("design:type", Date)
], Device.prototype, "createdAt", void 0);
__decorate([
    sequelize_typescript_1.UpdatedAt,
    __metadata("design:type", Date)
], Device.prototype, "updatedAt", void 0);
exports.Device = Device = __decorate([
    (0, sequelize_typescript_1.Table)({ tableName: 'devices', timestamps: true })
], Device);
//# sourceMappingURL=device.model.js.map