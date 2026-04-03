import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  createParamDecorator,
} from '@nestjs/common';
import { DevicesService } from './devices.service';

@Injectable()
export class DeviceGuard implements CanActivate {
  constructor(private readonly devicesService: DevicesService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const deviceUuid = request.headers['x-device-uuid'];

    if (!deviceUuid) {
      throw new UnauthorizedException('X-Device-UUID header is required');
    }

    const device = await this.devicesService.findByUuid(deviceUuid);
    if (!device) {
      throw new UnauthorizedException('Unknown device. Call POST /api/devices/register first');
    }

    request.device = device;
    return true;
  }
}

export const CurrentDevice = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext) => {
    return ctx.switchToHttp().getRequest().device;
  },
);
