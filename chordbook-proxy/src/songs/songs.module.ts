import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { Song } from '../database/song.model';
import { SongsController } from './songs.controller';
import { SongsService } from './songs.service';
import { ScraperModule } from '../scraper/scraper.module';

@Module({
  imports: [SequelizeModule.forFeature([Song]), ScraperModule],
  controllers: [SongsController],
  providers: [SongsService],
  exports: [SongsService],
})
export class SongsModule {}
