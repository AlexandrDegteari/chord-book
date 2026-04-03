import { DevicesService } from './devices.service';
export declare class DevicesController {
    private readonly devicesService;
    constructor(devicesService: DevicesService);
    register(body: {
        deviceUuid: string;
        nickname?: string;
    }): Promise<{
        error: string;
        id?: undefined;
        deviceUuid?: undefined;
        nickname?: undefined;
    } | {
        id: string;
        deviceUuid: string;
        nickname: string | null;
        error?: undefined;
    }>;
}
