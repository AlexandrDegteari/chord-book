import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { ConfigModule } from '@nestjs/config';
import { AdminController } from './admin.controller';
import { AdminGuard } from './admin.guard';
import { UserSongsModule } from '../user-songs/user-songs.module';
import { DevicesModule } from '../devices/devices.module';
import { SongsModule } from '../songs/songs.module';
import { CronModule } from '../cron/cron.module';
import { Song } from '../database/song.model';
import { Device } from '../database/device.model';
import { UserSong } from '../database/user-song.model';
import { Playlist } from '../database/playlist.model';

@Module({
  imports: [
    ConfigModule,
    SequelizeModule.forFeature([Song, Device, UserSong, Playlist]),
    UserSongsModule,
    DevicesModule,
    SongsModule,
    CronModule,
  ],
  controllers: [AdminController],
  providers: [AdminGuard],
})
export class AdminModule {}
