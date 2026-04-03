import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import axios, { AxiosRequestConfig } from 'axios';
import { load } from 'cheerio';
import * as puppeteer from 'puppeteer';
import { HttpsProxyAgent } from 'https-proxy-agent';

export class RateLimitError extends Error {
  constructor(message = 'Rate limited by mychords.net (429)') {
    super(message);
    this.name = 'RateLimitError';
  }
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

@Injectable()
export class ScraperService implements OnModuleDestroy {
  private readonly logger = new Logger(ScraperService.name);
  private readonly baseUrl = 'https://mychords.net';
  private readonly headers = {
    'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
  };

  private readonly chordRegex =
    /^([A-GH][#b]?)(m(?:aj)?|dim|aug|sus[24]?|add)?(\d+)?(sus[24])?(\/([A-GH][#b]?))?$/;

  private browser: puppeteer.Browser | null = null;

  // Rate limiting
  private lastRequestTime = 0;
  private readonly minRequestInterval = 3000; // 3 seconds between requests
  private backoffUntil = 0; // timestamp until which we should not make requests
  private backoffDuration = 30000; // starts at 30s, doubles on consecutive 429s

  // Proxy
  private readonly proxyUrl = process.env.SCRAPER_PROXY_URL || '';

  private getAxiosConfig(): AxiosRequestConfig {
    const config: AxiosRequestConfig = { headers: { ...this.headers } };
    if (this.proxyUrl) {
      config.httpsAgent = new HttpsProxyAgent(this.proxyUrl);
    }
    return config;
  }

  private async throttle(): Promise<void> {
    const now = Date.now();

    // Check backoff (from 429 responses)
    if (now < this.backoffUntil) {
      const wait = this.backoffUntil - now;
      this.logger.warn(`Rate limit backoff: waiting ${Math.round(wait / 1000)}s`);
      await new Promise((r) => setTimeout(r, wait));
    }

    // Enforce minimum interval between requests
    const elapsed = Date.now() - this.lastRequestTime;
    if (elapsed < this.minRequestInterval) {
      await new Promise((r) => setTimeout(r, this.minRequestInterval - elapsed));
    }
    this.lastRequestTime = Date.now();
  }

  private handle429(): void {
    this.backoffUntil = Date.now() + this.backoffDuration;
    this.logger.warn(`Got 429 — backing off for ${this.backoffDuration / 1000}s`);
    // Double backoff for next time, max 5 minutes
    this.backoffDuration = Math.min(this.backoffDuration * 2, 300000);
  }

  private resetBackoff(): void {
    this.backoffDuration = 30000;
  }

  private async getBrowser(): Promise<puppeteer.Browser> {
    if (!this.browser || !this.browser.connected) {
      const args = ['--no-sandbox', '--disable-setuid-sandbox'];
      if (this.proxyUrl) {
        args.push(`--proxy-server=${this.proxyUrl}`);
      }
      this.browser = await puppeteer.launch({ headless: true, args });
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
    await this.throttle();

    const config = this.getAxiosConfig();
    config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };

    let data: any;
    try {
      const resp = await axios.get(`${this.baseUrl}/en/ajax/autocomplete`, {
        ...config,
        params: { q: query },
      });
      if (resp.status === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      this.resetBackoff();
      data = resp.data;
    } catch (err) {
      if (err instanceof RateLimitError) throw err;
      if (err?.response?.status === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      throw err;
    }

    const results: SearchResult[] = [];

    if (data?.suggestions) {
      for (const suggestion of data.suggestions) {
        const url = suggestion.data?.url || '';
        const group = suggestion.data?.group || '';
        const value = suggestion.value || '';

        const idMatch = url.match(/\/(\d+)-/);

        if (group === 'Songs' && idMatch) {
          // The value field contains real Cyrillic names (e.g., "XOLIDAYBOY - Пожары")
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

  /**
   * Fetch the real Cyrillic name for a song by its external ID.
   * Uses the autocomplete API which returns Cyrillic in the value field.
   */
  async fetchRealName(externalId: string): Promise<{ title: string; artist: string } | null> {
    try {
      await this.throttle();
      const config = this.getAxiosConfig();
      config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };

      const resp = await axios.get(`${this.baseUrl}/en/ajax/autocomplete`, {
        ...config,
        params: { q: externalId },
      });

      if (resp.status === 429 || resp.data?.suggestions === undefined) {
        return null;
      }

      for (const suggestion of resp.data.suggestions || []) {
        const url = suggestion.data?.url || '';
        const group = suggestion.data?.group || '';
        const value = suggestion.value || '';

        if (group === 'Songs' && url.includes(`/${externalId}-`)) {
          const parts = value.split(' - ');
          if (parts.length > 1) {
            return {
              artist: parts[0].trim(),
              title: parts.slice(1).join(' - ').trim(),
            };
          }
        }
      }
    } catch {
      // Silently fail — name lookup is best-effort
    }
    return null;
  }

  async getArtistSongs(
    artistUrl: string,
    artistName: string,
  ): Promise<SearchResult[]> {
    await this.throttle();

    const config = this.getAxiosConfig();
    let data: string;
    try {
      const resp = await axios.get(artistUrl, config);
      if (resp.status === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      this.resetBackoff();
      data = resp.data;
    } catch (err) {
      if (err instanceof RateLimitError) throw err;
      if (err?.response?.status === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      throw err;
    }

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

  async getAllArtists(): Promise<Array<{ name: string; url: string }>> {
    const artistMap = new Map<string, { name: string; url: string }>();

    const queries = [
      ...('abcdefghijklmnopqrstuvwxyz'.split('')),
      ...('абвгдежзиклмнопрстуфхцчшщэюя'.split('')),
      'th', 'ch', 'sh', 'st', 'tr', 'br', 'cr', 'gr', 'fr', 'pr',
      'ac', 'ad', 'al', 'am', 'an', 'ar', 'ba', 'be', 'bi', 'bl',
      'bo', 'ca', 'co', 'da', 'de', 'di', 'do', 'dr', 'ed', 'el',
      'em', 'fl', 'fo', 'ga', 'ge', 'go', 'ha', 'he', 'ho', 'in',
      'ja', 'je', 'jo', 'ka', 'ke', 'ki', 'la', 'le', 'li', 'lo',
      'ma', 'me', 'mi', 'mo', 'mu', 'na', 'ne', 'ni', 'no',
      'pa', 'pe', 'ph', 'pi', 'pl', 'po', 'qu', 'ra', 're', 'ri',
      'ro', 'ru', 'sa', 'sc', 'se', 'si', 'sl', 'sm', 'sn', 'so',
      'sp', 'sq', 'su', 'sw', 'ta', 'te', 'ti', 'to', 'tu',
      'un', 'va', 'vi', 'wa', 'we', 'wi', 'yo', 'za',
      'ал', 'ан', 'ар', 'ба', 'бе', 'би', 'бу', 'ва', 'ви', 'вл',
      'га', 'гр', 'да', 'де', 'ди', 'до', 'ев', 'за', 'зе',
      'ив', 'ка', 'ки', 'ко', 'кр', 'ла', 'ле', 'ли', 'лу', 'лю',
      'ма', 'ме', 'ми', 'мо', 'му', 'на', 'не', 'ни', 'но',
      'ол', 'па', 'пе', 'по', 'пр', 'ра', 'ро', 'ру',
      'са', 'се', 'си', 'сл', 'сн', 'со', 'ст', 'та', 'те', 'ти',
      'тр', 'ук', 'фа', 'фл', 'ха', 'хо', 'це', 'чи', 'ша', 'шо',
      'эл', 'юр', 'яр',
    ];

    for (const q of queries) {
      try {
        await this.throttle();
        const config = this.getAxiosConfig();
        config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };

        const { data } = await axios.get(
          `${this.baseUrl}/en/ajax/autocomplete`,
          { ...config, params: { q } },
        );

        if (data?.suggestions) {
          for (const suggestion of data.suggestions) {
            const group = suggestion.data?.group || '';
            const url = suggestion.data?.url || '';
            const value = suggestion.value || '';

            if (group === 'Artists' && value) {
              const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
              if (!artistMap.has(value)) {
                artistMap.set(value, { name: value, url: fullUrl });
              }
            }
          }
        }
      } catch {
        await new Promise((r) => setTimeout(r, 5000));
      }
    }

    return Array.from(artistMap.values());
  }

  async getSong(id: string): Promise<Song> {
    await this.throttle();

    const config = this.getAxiosConfig();
    config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };

    let searchData: any;
    try {
      const resp = await axios.get(`${this.baseUrl}/en/ajax/autocomplete`, {
        ...config,
        params: { q: id },
      });
      if (resp.status === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      this.resetBackoff();
      searchData = resp.data;
    } catch (err) {
      if (err instanceof RateLimitError) throw err;
      if (err?.response?.status === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      throw err;
    }

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
      throw new Error(`Song with id ${id} not found`);
    }

    return this.getSongByUrl(songUrl);
  }

  async getSongByUrl(url: string): Promise<Song> {
    await this.throttle();

    const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;

    const idMatch = url.match(/\/(\d+)-/);
    const id = idMatch ? idMatch[1] : '0';

    // Use Puppeteer to render JS-decoded chords
    const browser = await this.getBrowser();
    const page = await browser.newPage();

    try {
      await page.setUserAgent(this.headers['User-Agent']);
      const response = await page.goto(fullUrl, { waitUntil: 'networkidle2', timeout: 15000 });

      // Check for rate limiting
      if (response && response.status() === 429) {
        this.handle429();
        throw new RateLimitError();
      }
      this.resetBackoff();

      // Wait for JS to decode chords
      await page.waitForSelector('.b-accord__symbol', { timeout: 5000 }).catch(() => {});
      await new Promise((r) => setTimeout(r, 1500));

      // Extract title and artist from page
      const pageTitle = await page.$eval('h1', (el) => el.textContent?.trim() || '').catch(() => '');
      const parts = pageTitle.split(' - ');
      let artist = parts.length > 1 ? parts[0].trim() : '';
      let title = parts.length > 1 ? parts.slice(1).join(' - ').trim() : pageTitle;

      // Try to get real Cyrillic name from autocomplete API
      const realName = await this.fetchRealName(id);
      if (realName) {
        artist = realName.artist;
        title = realName.title;
      }

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

      if (rawData.length === 0) {
        this.logger.warn(`Empty content extracted from ${fullUrl}`);
      }

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

    let bassNote = match[6] || undefined;
    if (bassNote === 'H') bassNote = 'B';
    else if (bassNote === 'Hb') bassNote = 'Bb';

    return {
      root,
      quality: (match[2] || '') + (match[3] || '') + (match[4] || ''),
      bassNote,
      position: 0,
    };
  }
}
