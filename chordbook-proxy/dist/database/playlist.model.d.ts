import { Model } from 'sequelize-typescript';
import { Device } from './device.model';
import { Song } from './song.model';
export declare class Playlist extends Model {
    id: string;
    deviceId: string;
    device: Device;
    title: string;
    description: string | null;
    isPublic: boolean;
    shareCode: string | null;
    songs: Song[];
    createdAt: Date;
    updatedAt: Date;
}
