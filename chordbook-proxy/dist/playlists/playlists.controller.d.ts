import { PlaylistsService } from './playlists.service';
import { Device } from '../database/device.model';
export declare class PlaylistsController {
    private readonly playlistsService;
    constructor(playlistsService: PlaylistsService);
    findAll(device: Device): Promise<import("../database").Playlist[]>;
    create(device: Device, body: {
        title: string;
        description?: string;
    }): Promise<import("../database").Playlist>;
    findOne(id: string, device: Device): Promise<import("../database").Playlist>;
    update(id: string, device: Device, body: {
        title?: string;
        description?: string;
        isPublic?: boolean;
    }): Promise<import("../database").Playlist>;
    remove(id: string, device: Device): Promise<{
        deleted: boolean;
    }>;
    addSong(id: string, device: Device, body: {
        songId: string;
    }): Promise<{
        added: boolean;
    }>;
    removeSong(id: string, songId: string, device: Device): Promise<{
        removed: boolean;
    }>;
    reorder(id: string, device: Device, body: {
        songIds: string[];
    }): Promise<{
        reordered: boolean;
    }>;
}
