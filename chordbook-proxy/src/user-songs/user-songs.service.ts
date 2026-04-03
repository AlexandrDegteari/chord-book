import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { UserSong } from '../database/user-song.model';
import { Song } from '../database/song.model';
import { randomBytes } from 'crypto';

@Injectable()
export class UserSongsService {
  constructor(
    @InjectModel(UserSong) private readonly userSongModel: typeof UserSong,
    @InjectModel(Song) private readonly songModel: typeof Song,
  ) {}

  async findAllByDevice(deviceId: string) {
    return this.userSongModel.findAll({
      where: { deviceId },
      order: [['createdAt', 'DESC']],
    });
  }

  async findById(id: string, deviceId?: string) {
    const song = await this.userSongModel.findByPk(id);
    if (!song) throw new NotFoundException('User song not found');
    if (!song.isPublic && song.deviceId !== deviceId) {
      throw new ForbiddenException('Access denied');
    }
    return song;
  }

  async create(deviceId: string, data: {
    title: string;
    artist: string;
    sections: any;
    originalSongId?: string;
  }) {
    return this.userSongModel.create({
      deviceId,
      title: data.title,
      artist: data.artist,
      sections: data.sections,
      originalSongId: data.originalSongId || null,
    });
  }

  async update(id: string, deviceId: string, data: {
    title?: string;
    artist?: string;
    sections?: any;
    isPublic?: boolean;
  }) {
    const song = await this.findOwned(id, deviceId);

    if (data.isPublic && !song.shareCode) {
      data['shareCode'] = randomBytes(9).toString('base64url').slice(0, 12);
    }

    await song.update(data);
    return song;
  }

  async delete(id: string, deviceId: string) {
    const song = await this.findOwned(id, deviceId);
    await song.destroy();
  }

  async submit(id: string, deviceId: string) {
    const song = await this.findOwned(id, deviceId);
    if (song.status !== 'draft' && song.status !== 'rejected') {
      throw new ForbiddenException('Can only submit drafts or rejected songs');
    }
    await song.update({ status: 'submitted' });
    return song;
  }

  async findByShareCode(code: string) {
    const song = await this.userSongModel.findOne({
      where: { shareCode: code, isPublic: true },
    });
    if (!song) throw new NotFoundException('Shared song not found');
    return song;
  }

  // Admin methods
  async findPending() {
    return this.userSongModel.findAll({
      where: { status: 'submitted' },
      order: [['createdAt', 'ASC']],
    });
  }

  async approve(id: string) {
    const userSong = await this.userSongModel.findByPk(id);
    if (!userSong) throw new NotFoundException('Song not found');

    // Add to main songs table
    await this.songModel.create({
      title: userSong.title,
      artist: userSong.artist,
      sections: userSong.sections,
      source: 'user',
      status: 'active',
      submittedBy: userSong.deviceId,
    });

    await userSong.update({ status: 'approved' });
    return userSong;
  }

  async reject(id: string, reason: string) {
    const userSong = await this.userSongModel.findByPk(id);
    if (!userSong) throw new NotFoundException('Song not found');
    await userSong.update({ status: 'rejected', adminNotes: reason });
    return userSong;
  }

  private async findOwned(id: string, deviceId: string) {
    const song = await this.userSongModel.findByPk(id);
    if (!song) throw new NotFoundException('User song not found');
    if (song.deviceId !== deviceId) throw new ForbiddenException('Not your song');
    return song;
  }
}
