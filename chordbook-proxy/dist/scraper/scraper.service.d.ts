import { OnModuleDestroy } from '@nestjs/common';
export declare class RateLimitError extends Error {
    constructor(message?: string);
}
export interface SearchResult {
    id: string;
    title: string;
    artist: string;
    url: string;
}
export interface ChordData {
    root: string;
    quality: string;
    bassNote?: string;
    position: number;
}
export interface SongLine {
    chords: ChordData[];
    lyrics: string;
}
export interface SongSection {
    label: string;
    lines: SongLine[];
}
export interface Song {
    id: string;
    title: string;
    artist: string;
    url: string;
    sections: SongSection[];
}
export declare class ScraperService implements OnModuleDestroy {
    private readonly logger;
    private readonly baseUrl;
    private readonly headers;
    private readonly chordRegex;
    private browser;
    private lastRequestTime;
    private readonly minRequestInterval;
    private backoffUntil;
    private backoffDuration;
    private readonly proxyUrl;
    private getAxiosConfig;
    private throttle;
    private handle429;
    private resetBackoff;
    private getBrowser;
    onModuleDestroy(): Promise<void>;
    search(query: string): Promise<SearchResult[]>;
    fetchRealName(externalId: string): Promise<{
        title: string;
        artist: string;
    } | null>;
    getArtistSongs(artistUrl: string, artistName: string): Promise<SearchResult[]>;
    getAllArtists(): Promise<Array<{
        name: string;
        url: string;
    }>>;
    getSong(id: string): Promise<Song>;
    getSongByUrl(url: string): Promise<Song>;
    private parseChordSymbol;
}
