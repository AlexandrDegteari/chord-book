import { Controller, Get, Param, Query } from '@nestjs/common';
import { ScraperService } from './scraper.service';

@Controller('api')
export class ScraperController {
  constructor(private readonly scraperService: ScraperService) {}

  @Get('search')
  async search(@Query('q') query: string) {
    if (!query || query.trim().length < 2) {
      return [];
    }
    return this.scraperService.search(query);
  }

  @Get('song/:id')
  async getSong(@Param('id') id: string) {
    return this.scraperService.getSong(id);
  }

  @Get('song-by-url')
  async getSongByUrl(@Query('url') url: string) {
    if (!url) {
      return { error: 'URL is required' };
    }
    return this.scraperService.getSongByUrl(url);
  }
}
