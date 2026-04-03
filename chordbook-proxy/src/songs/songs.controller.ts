import { Controller, Get, Param, Query, HttpException, HttpStatus } from '@nestjs/common';
import { SongsService } from './songs.service';
import { RateLimitError } from '../scraper/scraper.service';

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
    try {
      return await this.songsService.getSong(id);
    } catch (err) {
      if (err instanceof RateLimitError) {
        throw new HttpException('Server is busy, try again later', HttpStatus.TOO_MANY_REQUESTS);
      }
      throw err;
    }
  }

  @Get('song-by-url')
  async getSongByUrl(@Query('url') url: string) {
    if (!url) {
      return { error: 'URL is required' };
    }
    try {
      return await this.songsService.getSongByUrl(url);
    } catch (err) {
      if (err instanceof RateLimitError) {
        throw new HttpException('Server is busy, try again later', HttpStatus.TOO_MANY_REQUESTS);
      }
      throw err;
    }
  }
}
