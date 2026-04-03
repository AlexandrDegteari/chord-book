import { Controller, Post, Body } from '@nestjs/common';
import { DevicesService } from './devices.service';

@Controller('api/devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Post('register')
  async register(@Body() body: { deviceUuid: string; nickname?: string }) {
    if (!body.deviceUuid) {
      return { error: 'deviceUuid is required' };
    }
    const device = await this.devicesService.register(body.deviceUuid, body.nickname);
    return { id: device.id, deviceUuid: device.deviceUuid, nickname: device.nickname };
  }
}
