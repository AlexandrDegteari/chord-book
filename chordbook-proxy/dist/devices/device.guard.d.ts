import { CanActivate, ExecutionContext } from '@nestjs/common';
import { DevicesService } from './devices.service';
export declare class DeviceGuard implements CanActivate {
    private readonly devicesService;
    constructor(devicesService: DevicesService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
export declare const CurrentDevice: (...dataOrPipes: unknown[]) => ParameterDecorator;
