import {
  Controller, Get, Post, Put, Delete,
  Param, Body, UseGuards,
} from '@nestjs/common';
import { UserSongsService } from './user-songs.service';
import { DeviceGuard, CurrentDevice } from '../devices/device.guard';
import { Device } from '../database/device.model';

@Controller('api/user-songs')
@UseGuards(DeviceGuard)
export class UserSongsController {
  constructor(private readonly userSongsService: UserSongsService) {}

  @Get()
  async findAll(@CurrentDevice() device: Device) {
    return this.userSongsService.findAllByDevice(device.id);
  }

  @Post()
  async create(
    @CurrentDevice() device: Device,
    @Body() body: { title: string; artist: string; sections: any; originalSongId?: string },
  ) {
    return this.userSongsService.create(device.id, body);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentDevice() device: Device) {
    return this.userSongsService.findById(id, device.id);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @CurrentDevice() device: Device,
    @Body() body: { title?: string; artist?: string; sections?: any; isPublic?: boolean },
  ) {
    return this.userSongsService.update(id, device.id, body);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @CurrentDevice() device: Device) {
    await this.userSongsService.delete(id, device.id);
    return { deleted: true };
  }

  @Post(':id/submit')
  async submit(@Param('id') id: string, @CurrentDevice() device: Device) {
    return this.userSongsService.submit(id, device.id);
  }
}
