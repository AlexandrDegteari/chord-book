import { OnModuleDestroy } from '@nestjs/common';
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
    private readonly baseUrl;
    private readonly headers;
    private readonly chordRegex;
    private browser;
    private getBrowser;
    onModuleDestroy(): Promise<void>;
    search(query: string): Promise<SearchResult[]>;
    getArtistSongs(artistUrl: string, artistName: string): Promise<SearchResult[]>;
    getAllArtists(): Promise<Array<{
        name: string;
        url: string;
    }>>;
    getSong(id: string): Promise<Song>;
    getSongByUrl(url: string): Promise<Song>;
    private parseChordSymbol;
}
