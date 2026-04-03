import {
  Controller, Get, Post, Patch, Delete,
  Param, Body, UseGuards,
} from '@nestjs/common';
import { PlaylistsService } from './playlists.service';
import { DeviceGuard, CurrentDevice } from '../devices/device.guard';
import { Device } from '../database/device.model';

@Controller('api/playlists')
@UseGuards(DeviceGuard)
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  @Get()
  async findAll(@CurrentDevice() device: Device) {
    return this.playlistsService.findAllByDevice(device.id);
  }

  @Post()
  async create(
    @CurrentDevice() device: Device,
    @Body() body: { title: string; description?: string },
  ) {
    return this.playlistsService.create(device.id, body.title, body.description);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentDevice() device: Device) {
    return this.playlistsService.findById(id, device.id);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @CurrentDevice() device: Device,
    @Body() body: { title?: string; description?: string; isPublic?: boolean },
  ) {
    return this.playlistsService.update(id, device.id, body);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @CurrentDevice() device: Device) {
    await this.playlistsService.delete(id, device.id);
    return { deleted: true };
  }

  @Post(':id/songs')
  async addSong(
    @Param('id') id: string,
    @CurrentDevice() device: Device,
    @Body() body: { songId: string },
  ) {
    await this.playlistsService.addSong(id, body.songId, device.id);
    return { added: true };
  }

  @Delete(':id/songs/:songId')
  async removeSong(
    @Param('id') id: string,
    @Param('songId') songId: string,
    @CurrentDevice() device: Device,
  ) {
    await this.playlistsService.removeSong(id, songId, device.id);
    return { removed: true };
  }

  @Patch(':id/songs/reorder')
  async reorder(
    @Param('id') id: string,
    @CurrentDevice() device: Device,
    @Body() body: { songIds: string[] },
  ) {
    await this.playlistsService.reorderSongs(id, body.songIds, device.id);
    return { reordered: true };
  }
}
