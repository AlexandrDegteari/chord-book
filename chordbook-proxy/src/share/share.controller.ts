import { Controller, Get, Param } from '@nestjs/common';
import { PlaylistsService } from '../playlists/playlists.service';
import { UserSongsService } from '../user-songs/user-songs.service';

@Controller('api/share')
export class ShareController {
  constructor(
    private readonly playlistsService: PlaylistsService,
    private readonly userSongsService: UserSongsService,
  ) {}

  @Get('playlist/:code')
  async getSharedPlaylist(@Param('code') code: string) {
    return this.playlistsService.findByShareCode(code);
  }

  @Get('song/:code')
  async getSharedSong(@Param('code') code: string) {
    return this.userSongsService.findByShareCode(code);
  }
}
