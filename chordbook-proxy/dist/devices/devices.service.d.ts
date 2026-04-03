import { Device } from '../database/device.model';
export declare class DevicesService {
    private readonly deviceModel;
    constructor(deviceModel: typeof Device);
    register(deviceUuid: string, nickname?: string): Promise<Device>;
    findByUuid(deviceUuid: string): Promise<Device | null>;
    findAll(): Promise<Device[]>;
}
