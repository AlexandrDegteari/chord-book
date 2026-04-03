import { Module } from '@nestjs/common';
import { ShareController } from './share.controller';
import { PlaylistsModule } from '../playlists/playlists.module';
import { UserSongsModule } from '../user-songs/user-songs.module';

@Module({
  imports: [PlaylistsModule, UserSongsModule],
  controllers: [ShareController],
})
export class ShareModule {}
