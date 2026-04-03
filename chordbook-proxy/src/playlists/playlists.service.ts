import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Playlist } from '../database/playlist.model';
import { PlaylistSong } from '../database/playlist-song.model';
import { Song } from '../database/song.model';
import { randomBytes } from 'crypto';

@Injectable()
export class PlaylistsService {
  constructor(
    @InjectModel(Playlist) private readonly playlistModel: typeof Playlist,
    @InjectModel(PlaylistSong) private readonly playlistSongModel: typeof PlaylistSong,
  ) {}

  async findAllByDevice(deviceId: string) {
    return this.playlistModel.findAll({
      where: { deviceId },
      include: [{ model: Song, through: { attributes: ['position'] } }],
      order: [['createdAt', 'DESC']],
    });
  }

  async findById(id: string, deviceId?: string) {
    const playlist = await this.playlistModel.findByPk(id, {
      include: [{ model: Song, through: { attributes: ['position'] } }],
    });

    if (!playlist) throw new NotFoundException('Playlist not found');

    // Allow access if public or owned by device
    if (!playlist.isPublic && playlist.deviceId !== deviceId) {
      throw new ForbiddenException('Access denied');
    }

    return playlist;
  }

  async create(deviceId: string, title: string, description?: string) {
    return this.playlistModel.create({ deviceId, title, description });
  }

  async update(id: string, deviceId: string, data: { title?: string; description?: string; isPublic?: boolean }) {
    const playlist = await this.findOwned(id, deviceId);

    if (data.isPublic && !playlist.shareCode) {
      data['shareCode'] = randomBytes(9).toString('base64url').slice(0, 12);
    }

    await playlist.update(data);
    return playlist;
  }

  async delete(id: string, deviceId: string) {
    const playlist = await this.findOwned(id, deviceId);
    await playlist.destroy();
  }

  async addSong(playlistId: string, songId: string, deviceId: string) {
    await this.findOwned(playlistId, deviceId);

    const maxPos = await this.playlistSongModel.max('position', {
      where: { playlistId },
    }) as number | null;

    await this.playlistSongModel.findOrCreate({
      where: { playlistId, songId },
      defaults: { playlistId, songId, position: (maxPos || 0) + 1 },
    });
  }

  async removeSong(playlistId: string, songId: string, deviceId: string) {
    await this.findOwned(playlistId, deviceId);
    await this.playlistSongModel.destroy({ where: { playlistId, songId } });
  }

  async reorderSongs(playlistId: string, songIds: string[], deviceId: string) {
    await this.findOwned(playlistId, deviceId);

    for (let i = 0; i < songIds.length; i++) {
      await this.playlistSongModel.update(
        { position: i },
        { where: { playlistId, songId: songIds[i] } },
      );
    }
  }

  async findByShareCode(code: string) {
    const playlist = await this.playlistModel.findOne({
      where: { shareCode: code, isPublic: true },
      include: [{ model: Song, through: { attributes: ['position'] } }],
    });
    if (!playlist) throw new NotFoundException('Shared playlist not found');
    return playlist;
  }

  private async findOwned(id: string, deviceId: string) {
    const playlist = await this.playlistModel.findByPk(id);
    if (!playlist) throw new NotFoundException('Playlist not found');
    if (playlist.deviceId !== deviceId) throw new ForbiddenException('Not your playlist');
    return playlist;
  }
}
