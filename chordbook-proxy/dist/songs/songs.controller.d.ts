import { SongsService } from './songs.service';
export declare class SongsController {
    private readonly songsService;
    constructor(songsService: SongsService);
    search(query: string): Promise<{
        id: string;
        title: string;
        artist: string;
        url: string;
    }[]>;
    getSong(id: string): Promise<{
        id: string;
        title: string;
        artist: string;
        url: string;
        sections: any;
    }>;
    getSongByUrl(url: string): Promise<{
        id: string;
        title: string;
        artist: string;
        url: string;
        sections: any;
    } | {
        error: string;
    }>;
}
