import { Controller, Get, Param, Query } from '@nestjs/common';
import { SongsService } from './songs.service';

@Controller('api')
export class SongsController {
  constructor(private readonly songsService: SongsService) {}

  @Get('search')
  async search(@Query('q') query: string) {
    if (!query || query.trim().length < 2) {
      return [];
    }
    return this.songsService.search(query);
  }

  @Get('song/:id')
  async getSong(@Param('id') id: string) {
    return this.songsService.getSong(id);
  }

  @Get('song-by-url')
  async getSongByUrl(@Query('url') url: string) {
    if (!url) {
      return { error: 'URL is required' };
    }
    return this.songsService.getSongByUrl(url);
  }
}
