import { Injectable, OnModuleDestroy } from '@nestjs/common';
import axios from 'axios';
import { load } from 'cheerio';
import * as puppeteer from 'puppeteer';

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
export class ScraperService implements OnModuleDestroy {
  private readonly baseUrl = 'https://mychords.net';
  private readonly headers = {
    'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
  };

  private readonly chordRegex =
    /^([A-GH][#b]?)(m(?:aj)?|dim|aug|sus[24]?|add)?(\d+)?(\/([A-GH][#b]?))?$/;

  private browser: puppeteer.Browser | null = null;

  private async getBrowser(): Promise<puppeteer.Browser> {
    if (!this.browser || !this.browser.connected) {
      this.browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });
    }
    return this.browser;
  }

  async onModuleDestroy() {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }

  async search(query: string): Promise<SearchResult[]> {
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

        const idMatch = url.match(/\/(\d+)-/);

        if (group === 'Songs' && idMatch) {
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

    $('.b-listing__item__link').each((_, el) => {
      const href = $(el).attr('href') || '';
      const idMatch = href.match(/\/(\d+)-/);

      if (idMatch && href.endsWith('.html')) {
        const text = $(el).text().trim();
        if (text) {
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

    if (!songUrl) {
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

    return this.getSongByUrl(songUrl);
  }

  async getSongByUrl(url: string): Promise<Song> {
    const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;

    const idMatch = url.match(/\/(\d+)-/);
    const id = idMatch ? idMatch[1] : '0';

    // Use Puppeteer to render JS-decoded chords
    const browser = await this.getBrowser();
    const page = await browser.newPage();

    try {
      await page.setUserAgent(this.headers['User-Agent']);
      await page.goto(fullUrl, { waitUntil: 'networkidle2', timeout: 15000 });

      // Wait for JS to decode chords
      await page.waitForSelector('.b-accord__symbol', { timeout: 5000 }).catch(() => {});
      await new Promise((r) => setTimeout(r, 1500));

      // Extract title and artist
      const pageTitle = await page.$eval('h1', (el) => el.textContent?.trim() || '');
      const parts = pageTitle.split(' - ');
      const artist = parts.length > 1 ? parts[0].trim() : '';
      const title = parts.length > 1 ? parts.slice(1).join(' - ').trim() : pageTitle;

      // Extract all content from rendered DOM
      const rawData = await page.evaluate(() => {
        const content = document.querySelector('.w-words__text');
        if (!content) return [];

        const elements: Array<{
          type: string;
          classes: string;
          text: string;
          chords: string[];
          lyrics: string;
        }> = [];

        content.querySelectorAll(':scope > *').forEach((el) => {
          const classes = el.className || '';
          const text = el.textContent?.trim() || '';

          if (classes.includes('b-lr-section') || el.querySelector('.b-lr-section')) {
            const sectionEl = el.querySelector('.b-lr-section') || el;
            elements.push({ type: 'section', classes, text: sectionEl.textContent?.trim() || '', chords: [], lyrics: '' });
            return;
          }

          if (classes.includes('pline')) {
            const sublines = el.querySelectorAll('.subline');
            const chords: string[] = [];
            let lyrics = '';

            if (sublines.length >= 2) {
              sublines[0].querySelectorAll('.b-accord__symbol').forEach((c) => {
                const t = c.textContent?.trim();
                if (t) chords.push(t);
              });
              lyrics = sublines[sublines.length - 1].textContent?.replace(/\u00a0/g, ' ').trim() || '';
            }

            elements.push({ type: 'pline', classes, text, chords, lyrics });
            return;
          }

          if (classes.includes('single-line')) {
            const chords: string[] = [];
            el.querySelectorAll('.b-accord__symbol').forEach((c) => {
              const t = c.textContent?.trim();
              if (t) chords.push(t);
            });
            elements.push({ type: 'single-line', classes, text, chords, lyrics: text });
            return;
          }

          if (!text || text === '\u00a0') {
            elements.push({ type: 'empty', classes, text: '', chords: [], lyrics: '' });
            return;
          }

          elements.push({ type: 'text', classes, text, chords: [], lyrics: text });
        });

        return elements;
      });

      // Build sections from extracted data
      const sections: SongSection[] = [];
      let currentSection: SongSection = { label: '', lines: [] };

      for (const el of rawData) {
        if (el.type === 'section') {
          if (currentSection.lines.length > 0) {
            sections.push(currentSection);
          }
          currentSection = { label: el.text, lines: [] };
          continue;
        }

        if (el.type === 'pline') {
          const chords = el.chords
            .map((s) => this.parseChordSymbol(s))
            .filter((c): c is ChordData => c !== null);
          currentSection.lines.push({ chords, lyrics: el.lyrics });
          continue;
        }

        if (el.type === 'single-line') {
          if (el.chords.length > 0) {
            const chords = el.chords
              .map((s) => this.parseChordSymbol(s))
              .filter((c): c is ChordData => c !== null);
            currentSection.lines.push({ chords, lyrics: el.text });
          } else if (el.text) {
            currentSection.lines.push({ chords: [], lyrics: el.text });
          }
          continue;
        }

        if (el.type === 'empty') {
          if (currentSection.lines.length > 0) {
            sections.push(currentSection);
            currentSection = { label: '', lines: [] };
          }
          continue;
        }

        if (el.text) {
          currentSection.lines.push({ chords: [], lyrics: el.text });
        }
      }

      if (currentSection.lines.length > 0) {
        sections.push(currentSection);
      }

      return {
        id,
        title,
        artist,
        url: fullUrl,
        sections: sections.filter((s) => s.lines.length > 0),
      };
    } finally {
      await page.close();
    }
  }

  private parseChordSymbol(symbol: string): ChordData | null {
    const cleaned = symbol.trim().replace(/\(.*\)/, '');
    const match = cleaned.match(this.chordRegex);
    if (!match) return null;

    let root = match[1];
    if (root === 'H') root = 'B';
    else if (root === 'Hb') root = 'Bb';

    let bassNote = match[5] || undefined;
    if (bassNote === 'H') bassNote = 'B';
    else if (bassNote === 'Hb') bassNote = 'Bb';

    return {
      root,
      quality: (match[2] || '') + (match[3] || ''),
      bassNote,
      position: 0,
    };
  }
}
