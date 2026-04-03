import { Playlist } from '../database/playlist.model';
import { PlaylistSong } from '../database/playlist-song.model';
export declare class PlaylistsService {
    private readonly playlistModel;
    private readonly playlistSongModel;
    constructor(playlistModel: typeof Playlist, playlistSongModel: typeof PlaylistSong);
    findAllByDevice(deviceId: string): Promise<Playlist[]>;
    findById(id: string, deviceId?: string): Promise<Playlist>;
    create(deviceId: string, title: string, description?: string): Promise<Playlist>;
    update(id: string, deviceId: string, data: {
        title?: string;
        description?: string;
        isPublic?: boolean;
    }): Promise<Playlist>;
    delete(id: string, deviceId: string): Promise<void>;
    addSong(playlistId: string, songId: string, deviceId: string): Promise<void>;
    removeSong(playlistId: string, songId: string, deviceId: string): Promise<void>;
    reorderSongs(playlistId: string, songIds: string[], deviceId: string): Promise<void>;
    findByShareCode(code: string): Promise<Playlist>;
    private findOwned;
}
