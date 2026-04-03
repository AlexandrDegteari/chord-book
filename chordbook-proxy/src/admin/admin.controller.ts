import {
  Controller, Get, Post, Param, Body, Query, UseGuards,
} from '@nestjs/common';
import { Op, fn, col } from 'sequelize';
import { AdminGuard } from './admin.guard';
import { UserSongsService } from '../user-songs/user-songs.service';
import { DevicesService } from '../devices/devices.service';
import { CronService } from '../cron/cron.service';
import { InjectModel } from '@nestjs/sequelize';
import { Song } from '../database/song.model';
import { Device } from '../database/device.model';
import { UserSong } from '../database/user-song.model';
import { Playlist } from '../database/playlist.model';

@Controller('api/admin')
@UseGuards(AdminGuard)
export class AdminController {
  constructor(
    private readonly userSongsService: UserSongsService,
    private readonly devicesService: DevicesService,
    private readonly cronService: CronService,
    @InjectModel(Song) private readonly songModel: typeof Song,
    @InjectModel(Device) private readonly deviceModel: typeof Device,
    @InjectModel(UserSong) private readonly userSongModel: typeof UserSong,
    @InjectModel(Playlist) private readonly playlistModel: typeof Playlist,
  ) {}

  @Get('stats')
  async getStats() {
    const [songs, devices, playlists, pendingSongs, pendingImport, lastSyncResult] = await Promise.all([
      this.songModel.count({ where: { status: 'active' } }),
      this.deviceModel.count(),
      this.playlistModel.count(),
      this.userSongModel.count({ where: { status: 'submitted' } }),
      this.songModel.count({ where: { status: 'pending', source: 'scraped' } }),
      this.songModel.max('scrapedAt'),
    ]);
    return {
      songs,
      devices,
      playlists,
      pendingSongs,
      pendingImport,
      lastSync: lastSyncResult || null,
      scrapeStatus: this.cronService.getStatus(),
    };
  }

  @Get('pending-songs')
  async getPendingSongs() {
    return this.userSongsService.findPending();
  }

  @Get('pending-songs/:id')
  async getPendingSong(@Param('id') id: string) {
    return this.userSongsService.findById(id);
  }

  @Post('pending-songs/:id/approve')
  async approveSong(@Param('id') id: string) {
    return this.userSongsService.approve(id);
  }

  @Post('pending-songs/:id/reject')
  async rejectSong(@Param('id') id: string, @Body() body: { reason: string }) {
    return this.userSongsService.reject(id, body.reason);
  }

  @Get('devices')
  async getDevices() {
    return this.devicesService.findAll();
  }

  @Get('songs')
  async getSongs(
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '50',
    @Query('letter') letter?: string,
    @Query('search') search?: string,
  ) {
    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 50));
    const offset = (pageNum - 1) * limitNum;

    const where: any = {};

    if (letter === 'ALL_RU') {
      where.artist = { [Op.regexp]: '^[А-Яа-яЁё]' };
    } else if (letter) {
      where.artist = { [Op.iLike]: `${letter}%` };
    }

    if (search) {
      const conditions = [
        { title: { [Op.iLike]: `%${search}%` } },
        { artist: { [Op.iLike]: `%${search}%` } },
      ];
      // Transliterate cyrillic for search
      if (/[а-яё]/i.test(search)) {
        const map: Record<string, string> = {
          'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'zh',
          'з':'z','и':'i','й':'j','к':'k','л':'l','м':'m','н':'n','о':'o',
          'п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'h','ц':'c',
          'ч':'ch','ш':'sh','щ':'sch','ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya',
        };
        const translit = search.toLowerCase().split('').map(c => map[c] ?? c).join('');
        conditions.push(
          { title: { [Op.iLike]: `%${translit}%` } },
          { artist: { [Op.iLike]: `%${translit}%` } },
        );
      }
      where[Op.or] = conditions;
    }

    const { count, rows } = await this.songModel.findAndCountAll({
      where,
      order: letter ? [['artist', 'ASC'], ['title', 'ASC']] : [['title', 'ASC']],
      limit: limitNum,
      offset,
      attributes: { exclude: ['sections'] },
    });

    return {
      songs: rows,
      total: count,
      page: pageNum,
      totalPages: Math.ceil(count / limitNum),
    };
  }

  @Post('cron/full-scrape')
  async fullScrape() {
    // Run in background, return immediately
    const status = this.cronService.getStatus();
    if (status.isRunning) {
      return { error: 'Scrape already running' };
    }
    this.cronService.fullScrape();
    return { message: 'Full scrape started in background. Check server logs for progress.' };
  }

  @Get('cron/status')
  async cronStatus() {
    return this.cronService.getStatus();
  }

  @Post('bulk-import')
  async bulkImport(@Body() body: { songs: Array<{ id: string; title: string; artist: string; url: string }> }) {
    if (!body.songs || !Array.isArray(body.songs)) {
      return { error: 'songs array required' };
    }

    let imported = 0;
    let skipped = 0;

    for (const song of body.songs) {
      try {
        const exists = await this.songModel.findOne({ where: { externalId: song.id } });
        if (!exists) {
          await this.songModel.create({
            externalId: song.id,
            title: song.title,
            artist: song.artist,
            url: song.url,
            sections: [],
            source: 'scraped',
            status: 'pending',
            scrapedAt: new Date(),
          });
          imported++;
        } else {
          skipped++;
        }
      } catch {
        skipped++;
      }
    }

    return { imported, skipped, total: body.songs.length };
  }

  @Get('import-queue')
  async getImportQueue(
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '50',
    @Query('search') search?: string,
  ) {
    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 50));
    const offset = (pageNum - 1) * limitNum;

    const where: any = { status: 'pending', source: 'scraped' };

    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { artist: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await this.songModel.findAndCountAll({
      where,
      order: [['artist', 'ASC'], ['title', 'ASC']],
      limit: limitNum,
      offset,
      attributes: { exclude: ['sections'] },
    });

    return {
      songs: rows,
      total: count,
      page: pageNum,
      totalPages: Math.ceil(count / limitNum),
    };
  }

  @Post('import-queue/approve')
  async approveImport(@Body() body: { songIds: string[] }) {
    if (!body.songIds?.length) return { error: 'songIds required' };

    const [count] = await this.songModel.update(
      { status: 'active' },
      { where: { id: body.songIds, status: 'pending' } },
    );
    return { approved: count };
  }

  @Post('import-queue/approve-all')
  async approveAllImport() {
    const [count] = await this.songModel.update(
      { status: 'active' },
      { where: { status: 'pending', source: 'scraped' } },
    );
    return { approved: count };
  }

  @Post('import-queue/reject')
  async rejectImport(@Body() body: { songIds: string[] }) {
    if (!body.songIds?.length) return { error: 'songIds required' };

    await this.songModel.destroy({
      where: { id: body.songIds, status: 'pending' },
    });
    return { deleted: body.songIds.length };
  }

  @Post('save-names-file')
  async saveNamesFile(@Body() body: { songs: Array<{ id: string; title: string; artist: string }> }) {
    if (!body.songs?.length) return { error: 'no songs' };

    const fs = require('fs');
    const path = require('path');
    const filePath = path.join(__dirname, '..', '..', 'real_names.json');
    fs.writeFileSync(filePath, JSON.stringify(body.songs));
    return { saved: body.songs.length, path: filePath };
  }

  @Post('bulk-update-names')
  async bulkUpdateNames(@Body() body: { songs: Array<{ id: string; title: string; artist: string }> }) {
    if (!body.songs || !Array.isArray(body.songs)) {
      return { error: 'songs array required' };
    }

    // Batch UPDATE using raw SQL for speed
    const sequelize = this.songModel.sequelize!;
    let updated = 0;

    // Process in chunks of 100
    for (let i = 0; i < body.songs.length; i += 100) {
      const chunk = body.songs.slice(i, i + 100);
      const cases_title: string[] = [];
      const cases_artist: string[] = [];
      const ids: string[] = [];

      for (const s of chunk) {
        const escapedTitle = s.title.replace(/'/g, "''");
        const escapedArtist = s.artist.replace(/'/g, "''");
        cases_title.push(`WHEN "externalId" = '${s.id}' THEN '${escapedTitle}'`);
        cases_artist.push(`WHEN "externalId" = '${s.id}' THEN '${escapedArtist}'`);
        ids.push(`'${s.id}'`);
      }

      try {
        const [, result] = await sequelize.query(`
          UPDATE songs SET
            title = CASE ${cases_title.join(' ')} ELSE title END,
            artist = CASE ${cases_artist.join(' ')} ELSE artist END,
            "updatedAt" = NOW()
          WHERE "externalId" IN (${ids.join(',')})
        `);
        updated += (result as any)?.rowCount || chunk.length;
      } catch(e) {
        // fallback: skip chunk on error
      }
    }

    return { updated, total: body.songs.length };
  }
}
