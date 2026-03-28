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
export declare class ScraperService {
    private readonly baseUrl;
    private readonly headers;
    private readonly chordRegex;
    search(query: string): Promise<SearchResult[]>;
    private getArtistSongs;
    getSong(id: string): Promise<Song>;
    getSongByUrl(url: string): Promise<Song>;
    private parseSongPage;
    private parsePline;
    private parseChordSymbol;
    private parsePreformatted;
}
