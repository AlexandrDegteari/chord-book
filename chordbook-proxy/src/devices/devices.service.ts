import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Device } from '../database/device.model';

@Injectable()
export class DevicesService {
  constructor(@InjectModel(Device) private readonly deviceModel: typeof Device) {}

  async register(deviceUuid: string, nickname?: string) {
    const [device] = await this.deviceModel.findOrCreate({
      where: { deviceUuid },
      defaults: { deviceUuid, nickname: nickname || null },
    });
    return device;
  }

  async findByUuid(deviceUuid: string) {
    return this.deviceModel.findOne({ where: { deviceUuid } });
  }

  async findAll() {
    return this.deviceModel.findAll({ order: [['createdAt', 'DESC']] });
  }
}
