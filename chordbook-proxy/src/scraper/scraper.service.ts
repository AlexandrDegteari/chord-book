import { Injectable } from '@nestjs/common';
import axios from 'axios';
import { load } from 'cheerio';

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

@Injectable()
export class ScraperService {
  private readonly baseUrl = 'https://mychords.net';
  private readonly headers = {
    'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
  };

  private readonly chordRegex =
    /^([A-G][#b]?)(m(?:aj)?|dim|aug|sus[24]?|add)?(\d+)?(\/([A-G][#b]?))?$/;

  async search(query: string): Promise<SearchResult[]> {
    // Use the AJAX autocomplete API which returns JSON
    const { data } = await axios.get(
      `${this.baseUrl}/en/ajax/autocomplete`,
      {
        params: { q: query },
        headers: {
          ...this.headers,
          'X-Requested-With': 'XMLHttpRequest',
        },
      },
    );

    const results: SearchResult[] = [];

    if (data?.suggestions) {
      for (const suggestion of data.suggestions) {
        const url = suggestion.data?.url || '';
        const group = suggestion.data?.group || '';
        const value = suggestion.value || '';

        // Extract ID from URL like /en/artist/12345-song-name.html
        const idMatch = url.match(/\/(\d+)-/);

        if (group === 'Songs' && idMatch) {
          // Split "Artist - Song" format
          const parts = value.split(' - ');
          const artist = parts.length > 1 ? parts[0].trim() : '';
          const title =
            parts.length > 1 ? parts.slice(1).join(' - ').trim() : value;

          results.push({
            id: idMatch[1],
            title,
            artist,
            url: url.startsWith('http') ? url : `${this.baseUrl}${url}`,
          });
        } else if (group === 'Artists') {
          // Fetch artist page to get songs list
          const artistUrl = url.startsWith('http')
            ? url
            : `${this.baseUrl}${url}`;
          try {
            const artistResults = await this.getArtistSongs(
              artistUrl,
              value,
            );
            results.push(...artistResults.slice(0, 20));
          } catch {
            // Skip if artist page fails
          }
        }
      }
    }

    return results;
  }

  private async getArtistSongs(
    artistUrl: string,
    artistName: string,
  ): Promise<SearchResult[]> {
    const { data } = await axios.get(artistUrl, { headers: this.headers });
    const $ = load(data);
    const results: SearchResult[] = [];

    // Use the specific listing selector for artist song pages
    $('.b-listing__item__link').each((_, el) => {
      const href = $(el).attr('href') || '';
      const idMatch = href.match(/\/(\d+)-/);

      if (idMatch && href.endsWith('.html')) {
        const text = $(el).text().trim();
        if (text) {
          // Clean up: remove artist prefix and "(N versions)" suffix
          const title = text
            .replace(new RegExp(`^${artistName}\\s*-\\s*`, 'i'), '')
            .replace(/\s*\(\d+\s*versions?\)\s*/gi, '')
            .replace(/\s+/g, ' ')
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

  async getSong(id: string): Promise<Song> {
    // Search for the song URL via autocomplete
    const { data: searchData } = await axios.get(
      `${this.baseUrl}/en/ajax/autocomplete`,
      {
        params: { q: id },
        headers: {
          ...this.headers,
          'X-Requested-With': 'XMLHttpRequest',
        },
      },
    );

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

    // If not found via autocomplete, try constructing URL patterns
    if (!songUrl) {
      // Try fetching the main page to find the link
      const { data: mainData } = await axios.get(this.baseUrl, {
        headers: this.headers,
      });
      const $main = load(mainData);
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

    const { data: songData } = await axios.get(songUrl, {
      headers: this.headers,
    });

    return this.parseSongPage(songData, id, songUrl);
  }

  async getSongByUrl(url: string): Promise<Song> {
    const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
    const { data } = await axios.get(fullUrl, { headers: this.headers });

    const idMatch = url.match(/\/(\d+)-/);
    const id = idMatch ? idMatch[1] : '0';

    return this.parseSongPage(data, id, fullUrl);
  }

  private parseSongPage(html: string, id: string, url: string): Song {
    const $ = load(html);

    // Extract title and artist from page
    const pageTitle = $('h1').first().text().trim();
    const parts = pageTitle.split(' - ');
    const artist = parts.length > 1 ? parts[0].trim() : '';
    const title =
      parts.length > 1 ? parts.slice(1).join(' - ').trim() : pageTitle;

    // Parse chord content
    const sections: SongSection[] = [];
    let currentSection: SongSection = { label: '', lines: [] };

    const $content = $('.w-words__text');
    if ($content.length === 0) {
      // Fallback: try other selectors
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

      // Check if this element contains a section header
      const $sectionHeader = $el.find('.b-lr-section');
      if (
        classes.includes('b-lr-section') ||
        $sectionHeader.length > 0
      ) {
        if (currentSection.lines.length > 0) {
          sections.push(currentSection);
        }
        const label =
          $sectionHeader.length > 0 ? $sectionHeader.text().trim() : text;
        currentSection = { label, lines: [] };
        // If the element also contains lyrics (e.g. "Припев: guitar part"), add as line
        const remainingText = text.replace(label, '').trim();
        if (remainingText) {
          currentSection.lines.push({ chords: [], lyrics: text });
        }
        return;
      }

      // Chord+lyrics line (pline with c-subline)
      if (classes.includes('pline')) {
        const line = this.parsePline($, $el);
        currentSection.lines.push(line);
        return;
      }

      // Plain lyrics line or single-line with potential chords
      if (classes.includes('single-line')) {
        // Check if it contains chord symbols
        const $chordSymbols = $el.find('.b-accord__symbol');
        if ($chordSymbols.length > 0) {
          const chords: ChordData[] = [];
          $chordSymbols.each((_, chordEl) => {
            const symbol = $(chordEl).text().trim();
            const parsed = this.parseChordSymbol(symbol);
            if (parsed) chords.push(parsed);
          });
          // Get lyrics by removing chord symbols
          const lyrics = text;
          currentSection.lines.push({ chords, lyrics });
        } else if (text) {
          currentSection.lines.push({ chords: [], lyrics: text });
        }
        return;
      }

      // Tab line (subline with tab-row) — skip guitar tabs
      if (
        classes.includes('subline') &&
        $el.find('.b-words__tab-row').length > 0
      ) {
        return;
      }

      // Empty line / separator (&nbsp;)
      if (!text || text === '\u00a0') {
        if (currentSection.lines.length > 0) {
          sections.push(currentSection);
          currentSection = { label: '', lines: [] };
        }
        return;
      }

      // Fallback: treat as lyrics
      if (text) {
        currentSection.lines.push({ chords: [], lyrics: text });
      }
    });

    if (currentSection.lines.length > 0) {
      sections.push(currentSection);
    }

    // Filter out sections that only have tab lines (empty after filtering)
    return {
      id,
      title,
      artist,
      url,
      sections: sections.filter((s) => s.lines.length > 0),
    };
  }

  private parsePline($: ReturnType<typeof load>, $el: any): SongLine {
    const chords: ChordData[] = [];
    let lyrics = '';

    const $cSubline = $el.find('.c-subline');
    if ($cSubline.length > 0) {
      const $sublines = $cSubline.find('.subline');
      if ($sublines.length >= 2) {
        // First span.subline = chords, second span.subline = lyrics
        const $chordLine = $sublines.first();
        const $lyricLine = $sublines.last();

        // Extract chord symbols from .b-accord__symbol spans
        $chordLine.find('.b-accord__symbol').each((_, chordEl: any) => {
          const symbol = $(chordEl).text().trim();
          const parsed = this.parseChordSymbol(symbol);
          if (parsed) {
            chords.push(parsed);
          }
        });

        lyrics = $lyricLine.text().replace(/\u00a0/g, ' ').trim();
      }
    }

    // Fallback if c-subline structure not found
    if (chords.length === 0 && !lyrics) {
      const $sublines = $el.find('.subline');
      if ($sublines.length >= 2) {
        const $chordLine = $sublines.first();
        const $lyricLine = $sublines.last();

        $chordLine.find('.b-accord__symbol').each((_, chordEl: any) => {
          const symbol = $(chordEl).text().trim();
          const parsed = this.parseChordSymbol(symbol);
          if (parsed) chords.push(parsed);
        });

        lyrics = $lyricLine.text().replace(/\u00a0/g, ' ').trim();
      }
    }

    return { chords, lyrics };
  }

  private parseChordSymbol(symbol: string): ChordData | null {
    const cleaned = symbol.trim().replace(/\(.*\)/, ''); // Remove (VII) etc.
    const match = cleaned.match(this.chordRegex);
    if (!match) return null;

    return {
      root: match[1],
      quality: (match[2] || '') + (match[3] || ''),
      bassNote: match[5] || undefined,
      position: 0,
    };
  }

  private parsePreformatted(text: string): SongLine[] {
    const lines: SongLine[] = [];
    const rawLines = text.split('\n');

    for (const rawLine of rawLines) {
      const trimmed = rawLine.trim();
      if (!trimmed) continue;

      const tokens = trimmed.split(/\s+/);
      const allChords = tokens.every((t) => this.chordRegex.test(t));

      if (allChords && tokens.length > 0) {
        const chords = tokens
          .map((t) => this.parseChordSymbol(t))
          .filter((c): c is ChordData => c !== null);
        lines.push({ chords, lyrics: '' });
      } else {
        lines.push({ chords: [], lyrics: trimmed });
      }
    }

    return lines;
  }
}
