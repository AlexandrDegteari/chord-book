import { UserSong } from '../database/user-song.model';
import { Song } from '../database/song.model';
export declare class UserSongsService {
    private readonly userSongModel;
    private readonly songModel;
    constructor(userSongModel: typeof UserSong, songModel: typeof Song);
    findAllByDevice(deviceId: string): Promise<UserSong[]>;
    findById(id: string, deviceId?: string): Promise<UserSong>;
    create(deviceId: string, data: {
        title: string;
        artist: string;
        sections: any;
        originalSongId?: string;
    }): Promise<UserSong>;
    update(id: string, deviceId: string, data: {
        title?: string;
        artist?: string;
        sections?: any;
        isPublic?: boolean;
    }): Promise<UserSong>;
    delete(id: string, deviceId: string): Promise<void>;
    submit(id: string, deviceId: string): Promise<UserSong>;
    findByShareCode(code: string): Promise<UserSong>;
    findPending(): Promise<UserSong[]>;
    approve(id: string): Promise<UserSong>;
    reject(id: string, reason: string): Promise<UserSong>;
    private findOwned;
}
