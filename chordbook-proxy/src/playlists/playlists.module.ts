import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { Playlist } from '../database/playlist.model';
import { PlaylistSong } from '../database/playlist-song.model';
import { PlaylistsController } from './playlists.controller';
import { PlaylistsService } from './playlists.service';
import { DevicesModule } from '../devices/devices.module';

@Module({
  imports: [
    SequelizeModule.forFeature([Playlist, PlaylistSong]),
    DevicesModule,
  ],
  controllers: [PlaylistsController],
  providers: [PlaylistsService],
  exports: [PlaylistsService],
})
export class PlaylistsModule {}
