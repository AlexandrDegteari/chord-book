import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Song } from './song.model';
import { Device } from './device.model';
import { Playlist } from './playlist.model';
import { PlaylistSong } from './playlist-song.model';
import { UserSong } from './user-song.model';

@Module({
  imports: [
    SequelizeModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        dialect: 'postgres',
        host: config.get('DATABASE_HOST', 'localhost'),
        port: config.get<number>('DATABASE_PORT', 5432),
        username: config.get('DATABASE_USER', 'sixstrings'),
        password: config.get('DATABASE_PASSWORD', ''),
        database: config.get('DATABASE_NAME', 'sixstrings_db'),
        models: [Song, Device, Playlist, PlaylistSong, UserSong],
        autoLoadModels: true,
        synchronize: true,
        logging: false,
      }),
    }),
  ],
})
export class DatabaseModule {}
