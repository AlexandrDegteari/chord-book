import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { Song } from '../database/song.model';
import { CronService } from './cron.service';
import { ScraperModule } from '../scraper/scraper.module';

@Module({
  imports: [SequelizeModule.forFeature([Song]), ScraperModule],
  providers: [CronService],
  exports: [CronService],
})
export class CronModule {}
