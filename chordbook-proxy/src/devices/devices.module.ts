import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { Device } from '../database/device.model';
import { DevicesController } from './devices.controller';
import { DevicesService } from './devices.service';

@Module({
  imports: [SequelizeModule.forFeature([Device])],
  controllers: [DevicesController],
  providers: [DevicesService],
  exports: [DevicesService],
})
export class DevicesModule {}
