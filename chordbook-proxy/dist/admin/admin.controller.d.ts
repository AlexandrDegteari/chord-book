import { UserSongsService } from '../user-songs/user-songs.service';
import { DevicesService } from '../devices/devices.service';
import { CronService } from '../cron/cron.service';
import { Song } from '../database/song.model';
import { Device } from '../database/device.model';
import { UserSong } from '../database/user-song.model';
import { Playlist } from '../database/playlist.model';
export declare class AdminController {
    private readonly userSongsService;
    private readonly devicesService;
    private readonly cronService;
    private readonly songModel;
    private readonly deviceModel;
    private readonly userSongModel;
    private readonly playlistModel;
    constructor(userSongsService: UserSongsService, devicesService: DevicesService, cronService: CronService, songModel: typeof Song, deviceModel: typeof Device, userSongModel: typeof UserSong, playlistModel: typeof Playlist);
    getStats(): Promise<{
        songs: number;
        devices: number;
        playlists: number;
        pendingSongs: number;
        pendingImport: number;
        lastSync: {} | null;
        scrapeStatus: {
            isRunning: boolean;
        };
    }>;
    getPendingSongs(): Promise<UserSong[]>;
    getPendingSong(id: string): Promise<UserSong>;
    approveSong(id: string): Promise<UserSong>;
    rejectSong(id: string, body: {
        reason: string;
    }): Promise<UserSong>;
    getDevices(): Promise<Device[]>;
    getSongs(page?: string, limit?: string, letter?: string, search?: string): Promise<{
        songs: Song[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    fullScrape(): Promise<{
        error: string;
        message?: undefined;
    } | {
        message: string;
        error?: undefined;
    }>;
    cronStatus(): Promise<{
        isRunning: boolean;
    }>;
    bulkImport(body: {
        songs: Array<{
            id: string;
            title: string;
            artist: string;
            url: string;
        }>;
    }): Promise<{
        error: string;
        imported?: undefined;
        skipped?: undefined;
        total?: undefined;
    } | {
        imported: number;
        skipped: number;
        total: number;
        error?: undefined;
    }>;
    getImportQueue(page?: string, limit?: string, search?: string): Promise<{
        songs: Song[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    approveImport(body: {
        songIds: string[];
    }): Promise<{
        error: string;
        approved?: undefined;
    } | {
        approved: number;
        error?: undefined;
    }>;
    approveAllImport(): Promise<{
        approved: number;
    }>;
    rejectImport(body: {
        songIds: string[];
    }): Promise<{
        error: string;
        deleted?: undefined;
    } | {
        deleted: number;
        error?: undefined;
    }>;
    saveNamesFile(body: {
        songs: Array<{
            id: string;
            title: string;
            artist: string;
        }>;
    }): Promise<{
        error: string;
        saved?: undefined;
        path?: undefined;
    } | {
        saved: number;
        path: any;
        error?: undefined;
    }>;
    bulkUpdateNames(body: {
        songs: Array<{
            id: string;
            title: string;
            artist: string;
        }>;
    }): Promise<{
        error: string;
        updated?: undefined;
        total?: undefined;
    } | {
        updated: number;
        total: number;
        error?: undefined;
    }>;
}
