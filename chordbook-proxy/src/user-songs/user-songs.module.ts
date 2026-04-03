import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { UserSong } from '../database/user-song.model';
import { Song } from '../database/song.model';
import { UserSongsController } from './user-songs.controller';
import { UserSongsService } from './user-songs.service';
import { DevicesModule } from '../devices/devices.module';

@Module({
  imports: [
    SequelizeModule.forFeature([UserSong, Song]),
    DevicesModule,
  ],
  controllers: [UserSongsController],
  providers: [UserSongsService],
  exports: [UserSongsService],
})
export class UserSongsModule {}
