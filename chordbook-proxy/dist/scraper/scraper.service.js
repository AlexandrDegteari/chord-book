"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScraperService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = __importDefault(require("axios"));
const cheerio_1 = require("cheerio");
let ScraperService = class ScraperService {
    baseUrl = 'https://mychords.net';
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
    };
    chordRegex = /^([A-G][#b]?)(m(?:aj)?|dim|aug|sus[24]?|add)?(\d+)?(\/([A-G][#b]?))?$/;
    async search(query) {
        const { data } = await axios_1.default.get(`${this.baseUrl}/en/ajax/autocomplete`, {
            params: { q: query },
            headers: {
                ...this.headers,
                'X-Requested-With': 'XMLHttpRequest',
            },
        });
        const results = [];
        if (data?.suggestions) {
            for (const suggestion of data.suggestions) {
                const url = suggestion.data?.url || '';
                const group = suggestion.data?.group || '';
                const value = suggestion.value || '';
                const idMatch = url.match(/\/(\d+)-/);
                if (group === 'Songs' && idMatch) {
                    const parts = value.split(' - ');
                    const artist = parts.length > 1 ? parts[0].trim() : '';
                    const title = parts.length > 1 ? parts.slice(1).join(' - ').trim() : value;
                    results.push({
                        id: idMatch[1],
                        title,
                        artist,
                        url: url.startsWith('http') ? url : `${this.baseUrl}${url}`,
                    });
                }
                else if (group === 'Artists') {
                    const artistUrl = url.startsWith('http')
                        ? url
                        : `${this.baseUrl}${url}`;
                    try {
                        const artistResults = await this.getArtistSongs(artistUrl, value);
                        results.push(...artistResults.slice(0, 20));
                    }
                    catch {
                    }
                }
            }
        }
        return results;
    }
    async getArtistSongs(artistUrl, artistName) {
        const { data } = await axios_1.default.get(artistUrl, { headers: this.headers });
        const $ = (0, cheerio_1.load)(data);
        const results = [];
        $('a').each((_, el) => {
            const href = $(el).attr('href') || '';
            const idMatch = href.match(/\/(\d+)-/);
            if (idMatch && href.endsWith('.html')) {
                const text = $(el).text().trim();
                if (text && !text.includes('\n')) {
                    const title = text
                        .replace(new RegExp(`^${artistName}\\s*-\\s*`, 'i'), '')
                        .trim();
                    if (title && !results.some((r) => r.id === idMatch[1])) {
                        results.push({
                            id: idMatch[1],
                            title: title || text,
                            artist: artistName,
                            url: href.startsWith('http') ? href : `${this.baseUrl}${href}`,
                        });
                    }
                }
            }
        });
        return results;
    }
    async getSong(id) {
        const { data: searchData } = await axios_1.default.get(`${this.baseUrl}/en/ajax/autocomplete`, {
            params: { q: id },
            headers: {
                ...this.headers,
                'X-Requested-With': 'XMLHttpRequest',
            },
        });
        let songUrl = '';
        if (searchData?.suggestions) {
            for (const suggestion of searchData.suggestions) {
                const url = suggestion.data?.url || '';
                if (url.includes(`/${id}-`)) {
                    songUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
                    break;
                }
            }
        }
        if (!songUrl) {
            const { data: mainData } = await axios_1.default.get(this.baseUrl, {
                headers: this.headers,
            });
            const $main = (0, cheerio_1.load)(mainData);
            $main(`a[href*="/${id}-"]`).each((_, el) => {
                const href = $main(el).attr('href') || '';
                if (href.endsWith('.html')) {
                    songUrl = href.startsWith('http') ? href : `${this.baseUrl}${href}`;
                }
            });
        }
        if (!songUrl) {
            throw new Error(`Song with id ${id} not found`);
        }
        const { data: songData } = await axios_1.default.get(songUrl, {
            headers: this.headers,
        });
        return this.parseSongPage(songData, id, songUrl);
    }
    async getSongByUrl(url) {
        const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
        const { data } = await axios_1.default.get(fullUrl, { headers: this.headers });
        const idMatch = url.match(/\/(\d+)-/);
        const id = idMatch ? idMatch[1] : '0';
        return this.parseSongPage(data, id, fullUrl);
    }
    parseSongPage(html, id, url) {
        const $ = (0, cheerio_1.load)(html);
        const pageTitle = $('h1').first().text().trim();
        const parts = pageTitle.split(' - ');
        const artist = parts.length > 1 ? parts[0].trim() : '';
        const title = parts.length > 1 ? parts.slice(1).join(' - ').trim() : pageTitle;
        const sections = [];
        let currentSection = { label: '', lines: [] };
        const $content = $('.w-words__text');
        if ($content.length === 0) {
            const $alt = $('pre, .chord-text, .song-text');
            if ($alt.length > 0) {
                currentSection.lines = this.parsePreformatted($alt.text());
                sections.push(currentSection);
                return { id, title, artist, url, sections };
            }
        }
        $content.children().each((_, el) => {
            const $el = $(el);
            const classes = $el.attr('class') || '';
            const text = $el.text().trim();
            const $sectionHeader = $el.find('.b-lr-section');
            if (classes.includes('b-lr-section') ||
                $sectionHeader.length > 0) {
                if (currentSection.lines.length > 0) {
                    sections.push(currentSection);
                }
                const label = $sectionHeader.length > 0 ? $sectionHeader.text().trim() : text;
                currentSection = { label, lines: [] };
                const remainingText = text.replace(label, '').trim();
                if (remainingText) {
                    currentSection.lines.push({ chords: [], lyrics: text });
                }
                return;
            }
            if (classes.includes('pline')) {
                const line = this.parsePline($, $el);
                currentSection.lines.push(line);
                return;
            }
            if (classes.includes('single-line')) {
                const $chordSymbols = $el.find('.b-accord__symbol');
                if ($chordSymbols.length > 0) {
                    const chords = [];
                    $chordSymbols.each((_, chordEl) => {
                        const symbol = $(chordEl).text().trim();
                        const parsed = this.parseChordSymbol(symbol);
                        if (parsed)
                            chords.push(parsed);
                    });
                    const lyrics = text;
                    currentSection.lines.push({ chords, lyrics });
                }
                else if (text) {
                    currentSection.lines.push({ chords: [], lyrics: text });
                }
                return;
            }
            if (classes.includes('subline') &&
                $el.find('.b-words__tab-row').length > 0) {
                return;
            }
            if (!text || text === '\u00a0') {
                if (currentSection.lines.length > 0) {
                    sections.push(currentSection);
                    currentSection = { label: '', lines: [] };
                }
                return;
            }
            if (text) {
                currentSection.lines.push({ chords: [], lyrics: text });
            }
        });
        if (currentSection.lines.length > 0) {
            sections.push(currentSection);
        }
        return {
            id,
            title,
            artist,
            url,
            sections: sections.filter((s) => s.lines.length > 0),
        };
    }
    parsePline($, $el) {
        const chords = [];
        let lyrics = '';
        const $cSubline = $el.find('.c-subline');
        if ($cSubline.length > 0) {
            const $sublines = $cSubline.find('.subline');
            if ($sublines.length >= 2) {
                const $chordLine = $sublines.first();
                const $lyricLine = $sublines.last();
                $chordLine.find('.b-accord__symbol').each((_, chordEl) => {
                    const symbol = $(chordEl).text().trim();
                    const parsed = this.parseChordSymbol(symbol);
                    if (parsed) {
                        chords.push(parsed);
                    }
                });
                lyrics = $lyricLine.text().replace(/\u00a0/g, ' ').trim();
            }
        }
        if (chords.length === 0 && !lyrics) {
            const $sublines = $el.find('.subline');
            if ($sublines.length >= 2) {
                const $chordLine = $sublines.first();
                const $lyricLine = $sublines.last();
                $chordLine.find('.b-accord__symbol').each((_, chordEl) => {
                    const symbol = $(chordEl).text().trim();
                    const parsed = this.parseChordSymbol(symbol);
                    if (parsed)
                        chords.push(parsed);
                });
                lyrics = $lyricLine.text().replace(/\u00a0/g, ' ').trim();
            }
        }
        return { chords, lyrics };
    }
    parseChordSymbol(symbol) {
        const cleaned = symbol.trim().replace(/\(.*\)/, '');
        const match = cleaned.match(this.chordRegex);
        if (!match)
            return null;
        return {
            root: match[1],
            quality: (match[2] || '') + (match[3] || ''),
            bassNote: match[5] || undefined,
            position: 0,
        };
    }
    parsePreformatted(text) {
        const lines = [];
        const rawLines = text.split('\n');
        for (const rawLine of rawLines) {
            const trimmed = rawLine.trim();
            if (!trimmed)
                continue;
            const tokens = trimmed.split(/\s+/);
            const allChords = tokens.every((t) => this.chordRegex.test(t));
            if (allChords && tokens.length > 0) {
                const chords = tokens
                    .map((t) => this.parseChordSymbol(t))
                    .filter((c) => c !== null);
                lines.push({ chords, lyrics: '' });
            }
            else {
                lines.push({ chords: [], lyrics: trimmed });
            }
        }
        return lines;
    }
};
exports.ScraperService = ScraperService;
exports.ScraperService = ScraperService = __decorate([
    (0, common_1.Injectable)()
], ScraperService);
//# sourceMappingURL=scraper.service.js.map