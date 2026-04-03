import { Model } from 'sequelize-typescript';
import { Playlist } from './playlist.model';
import { UserSong } from './user-song.model';
export declare class Device extends Model {
    id: string;
    deviceUuid: string;
    nickname: string | null;
    playlists: Playlist[];
    userSongs: UserSong[];
    createdAt: Date;
    updatedAt: Date;
}
