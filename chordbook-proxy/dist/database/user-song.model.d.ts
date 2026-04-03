import { Model } from 'sequelize-typescript';
import { Device } from './device.model';
import { Song } from './song.model';
export declare class UserSong extends Model {
    id: string;
    deviceId: string;
    device: Device;
    originalSongId: string | null;
    originalSong: Song;
    title: string;
    artist: string;
    sections: any;
    isPublic: boolean;
    shareCode: string | null;
    status: 'draft' | 'submitted' | 'approved' | 'rejected';
    adminNotes: string | null;
    createdAt: Date;
    updatedAt: Date;
}
