import { PlaylistsService } from '../playlists/playlists.service';
import { UserSongsService } from '../user-songs/user-songs.service';
export declare class ShareController {
    private readonly playlistsService;
    private readonly userSongsService;
    constructor(playlistsService: PlaylistsService, userSongsService: UserSongsService);
    getSharedPlaylist(code: string): Promise<import("../database").Playlist>;
    getSharedSong(code: string): Promise<import("../database").UserSong>;
}
