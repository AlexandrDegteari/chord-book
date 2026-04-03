import { UserSongsService } from './user-songs.service';
import { Device } from '../database/device.model';
export declare class UserSongsController {
    private readonly userSongsService;
    constructor(userSongsService: UserSongsService);
    findAll(device: Device): Promise<import("../database").UserSong[]>;
    create(device: Device, body: {
        title: string;
        artist: string;
        sections: any;
        originalSongId?: string;
    }): Promise<import("../database").UserSong>;
    findOne(id: string, device: Device): Promise<import("../database").UserSong>;
    update(id: string, device: Device, body: {
        title?: string;
        artist?: string;
        sections?: any;
        isPublic?: boolean;
    }): Promise<import("../database").UserSong>;
    remove(id: string, device: Device): Promise<{
        deleted: boolean;
    }>;
    submit(id: string, device: Device): Promise<import("../database").UserSong>;
}
