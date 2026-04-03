import { Model } from 'sequelize-typescript';
import { Device } from './device.model';
export declare class Song extends Model {
    id: string;
    externalId: string | null;
    title: string;
    artist: string;
    url: string | null;
    sections: any;
    source: 'scraped' | 'user';
    status: 'active' | 'pending' | 'rejected';
    submittedBy: string | null;
    submitter: Device;
    scrapedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
}
