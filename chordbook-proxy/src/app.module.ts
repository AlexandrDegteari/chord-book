import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { join } from 'path';
import { ScheduleModule } from '@nestjs/schedule';
import { DatabaseModule } from './database/database.module';
import { ScraperModule } from './scraper/scraper.module';
import { SongsModule } from './songs/songs.module';
import { DevicesModule } from './devices/devices.module';
import { PlaylistsModule } from './playlists/playlists.module';
import { UserSongsModule } from './user-songs/user-songs.module';
import { ShareModule } from './share/share.module';
import { AdminModule } from './admin/admin.module';
import { CronModule } from './cron/cron.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: join(__dirname, '..', '.env'),
    }),
    ScheduleModule.forRoot(),
    DatabaseModule,
    ScraperModule,
    SongsModule,
    DevicesModule,
    PlaylistsModule,
    UserSongsModule,
    ShareModule,
    AdminModule,
    CronModule,
  ],
})
export class AppModule {}
