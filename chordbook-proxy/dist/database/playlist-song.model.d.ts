import { Model } from 'sequelize-typescript';
export declare class PlaylistSong extends Model {
    id: string;
    playlistId: string;
    songId: string;
    position: number;
    addedAt: Date;
}
