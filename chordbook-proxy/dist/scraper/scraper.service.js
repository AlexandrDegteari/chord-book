"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var ScraperService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScraperService = exports.RateLimitError = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = __importDefault(require("axios"));
const cheerio_1 = require("cheerio");
const puppeteer = __importStar(require("puppeteer"));
const https_proxy_agent_1 = require("https-proxy-agent");
class RateLimitError extends Error {
    constructor(message = 'Rate limited by mychords.net (429)') {
        super(message);
        this.name = 'RateLimitError';
    }
}
exports.RateLimitError = RateLimitError;
let ScraperService = ScraperService_1 = class ScraperService {
    logger = new common_1.Logger(ScraperService_1.name);
    baseUrl = 'https://mychords.net';
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
    };
    chordRegex = /^([A-GH][#b]?)(m(?:aj)?|dim|aug|sus[24]?|add)?(\d+)?(sus[24])?(\/([A-GH][#b]?))?$/;
    browser = null;
    lastRequestTime = 0;
    minRequestInterval = 3000;
    maxRequestInterval = 6000;
    backoffUntil = 0;
    backoffDuration = 30000;
    proxyUrl = process.env.SCRAPER_PROXY_URL || '';
    getAxiosConfig() {
        const config = { headers: { ...this.headers } };
        if (this.proxyUrl) {
            config.httpsAgent = new https_proxy_agent_1.HttpsProxyAgent(this.proxyUrl);
        }
        return config;
    }
    async throttle() {
        const now = Date.now();
        if (now < this.backoffUntil) {
            const wait = this.backoffUntil - now;
            this.logger.warn(`Rate limit backoff: waiting ${Math.round(wait / 1000)}s`);
            await new Promise((r) => setTimeout(r, wait));
        }
        const interval = this.minRequestInterval + Math.random() * (this.maxRequestInterval - this.minRequestInterval);
        const elapsed = Date.now() - this.lastRequestTime;
        if (elapsed < interval) {
            await new Promise((r) => setTimeout(r, interval - elapsed));
        }
        this.lastRequestTime = Date.now();
    }
    handle429() {
        this.backoffUntil = Date.now() + this.backoffDuration;
        this.logger.warn(`Got 429 — backing off for ${this.backoffDuration / 1000}s`);
        this.backoffDuration = Math.min(this.backoffDuration * 2, 300000);
    }
    resetBackoff() {
        this.backoffDuration = 30000;
    }
    async getBrowser() {
        if (!this.browser || !this.browser.connected) {
            const args = ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu'];
            if (this.proxyUrl) {
                args.push(`--proxy-server=${this.proxyUrl}`);
            }
            this.browser = await puppeteer.launch({
                headless: true,
                args,
                executablePath: process.env.CHROME_PATH || undefined,
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
    async search(query) {
        await this.throttle();
        const config = this.getAxiosConfig();
        config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };
        let data;
        try {
            const resp = await axios_1.default.get(`${this.baseUrl}/en/ajax/autocomplete`, {
                ...config,
                params: { q: query },
            });
            if (resp.status === 429) {
                this.handle429();
                throw new RateLimitError();
            }
            this.resetBackoff();
            data = resp.data;
        }
        catch (err) {
            if (err instanceof RateLimitError)
                throw err;
            if (err?.response?.status === 429) {
                this.handle429();
                throw new RateLimitError();
            }
            throw err;
        }
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
    async fetchRealName(externalId) {
        try {
            await this.throttle();
            const config = this.getAxiosConfig();
            config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };
            const resp = await axios_1.default.get(`${this.baseUrl}/en/ajax/autocomplete`, {
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
        }
        catch {
        }
        return null;
    }
    async getArtistSongs(artistUrl, artistName) {
        await this.throttle();
        const config = this.getAxiosConfig();
        let data;
        try {
            const resp = await axios_1.default.get(artistUrl, config);
            if (resp.status === 429) {
                this.handle429();
                throw new RateLimitError();
            }
            this.resetBackoff();
            data = resp.data;
        }
        catch (err) {
            if (err instanceof RateLimitError)
                throw err;
            if (err?.response?.status === 429) {
                this.handle429();
                throw new RateLimitError();
            }
            throw err;
        }
        const $ = (0, cheerio_1.load)(data);
        const results = [];
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
    async getAllArtists() {
        const artistMap = new Map();
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
                const { data } = await axios_1.default.get(`${this.baseUrl}/en/ajax/autocomplete`, { ...config, params: { q } });
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
            }
            catch {
                await new Promise((r) => setTimeout(r, 5000));
            }
        }
        return Array.from(artistMap.values());
    }
    async getSong(id) {
        await this.throttle();
        const config = this.getAxiosConfig();
        config.headers = { ...config.headers, 'X-Requested-With': 'XMLHttpRequest' };
        let searchData;
        try {
            const resp = await axios_1.default.get(`${this.baseUrl}/en/ajax/autocomplete`, {
                ...config,
                params: { q: id },
            });
            if (resp.status === 429) {
                this.handle429();
                throw new RateLimitError();
            }
            this.resetBackoff();
            searchData = resp.data;
        }
        catch (err) {
            if (err instanceof RateLimitError)
                throw err;
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
    async getSongByUrl(url) {
        await this.throttle();
        const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
        const idMatch = url.match(/\/(\d+)-/);
        const id = idMatch ? idMatch[1] : '0';
        const browser = await this.getBrowser();
        const page = await browser.newPage();
        try {
            await page.setUserAgent(this.headers['User-Agent']);
            const response = await page.goto(fullUrl, { waitUntil: 'networkidle2', timeout: 15000 });
            if (response && response.status() === 429) {
                this.handle429();
                throw new RateLimitError();
            }
            this.resetBackoff();
            await page.waitForSelector('.b-accord__symbol', { timeout: 5000 }).catch(() => { });
            await new Promise((r) => setTimeout(r, 1500));
            const pageTitle = await page.$eval('h1', (el) => el.textContent?.trim() || '').catch(() => '');
            const parts = pageTitle.split(' - ');
            let artist = parts.length > 1 ? parts[0].trim() : '';
            let title = parts.length > 1 ? parts.slice(1).join(' - ').trim() : pageTitle;
            const realName = await this.fetchRealName(id);
            if (realName) {
                artist = realName.artist;
                title = realName.title;
            }
            const rawData = await page.evaluate(() => {
                const content = document.querySelector('.w-words__text');
                if (!content)
                    return [];
                const elements = [];
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
                        const chords = [];
                        let lyrics = '';
                        if (sublines.length >= 2) {
                            sublines[0].querySelectorAll('.b-accord__symbol').forEach((c) => {
                                const t = c.textContent?.trim();
                                if (t)
                                    chords.push(t);
                            });
                            lyrics = sublines[sublines.length - 1].textContent?.replace(/\u00a0/g, ' ').trim() || '';
                        }
                        elements.push({ type: 'pline', classes, text, chords, lyrics });
                        return;
                    }
                    if (classes.includes('single-line')) {
                        const chords = [];
                        el.querySelectorAll('.b-accord__symbol').forEach((c) => {
                            const t = c.textContent?.trim();
                            if (t)
                                chords.push(t);
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
            const sections = [];
            let currentSection = { label: '', lines: [] };
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
                        .filter((c) => c !== null);
                    currentSection.lines.push({ chords, lyrics: el.lyrics });
                    continue;
                }
                if (el.type === 'single-line') {
                    if (el.chords.length > 0) {
                        const chords = el.chords
                            .map((s) => this.parseChordSymbol(s))
                            .filter((c) => c !== null);
                        currentSection.lines.push({ chords, lyrics: el.text });
                    }
                    else if (el.text) {
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
        }
        finally {
            await page.close();
        }
    }
    parseChordSymbol(symbol) {
        const cleaned = symbol.trim().replace(/\(.*\)/, '');
        const match = cleaned.match(this.chordRegex);
        if (!match)
            return null;
        let root = match[1];
        if (root === 'H')
            root = 'B';
        else if (root === 'Hb')
            root = 'Bb';
        let bassNote = match[6] || undefined;
        if (bassNote === 'H')
            bassNote = 'B';
        else if (bassNote === 'Hb')
            bassNote = 'Bb';
        return {
            root,
            quality: (match[2] || '') + (match[3] || '') + (match[4] || ''),
            bassNote,
            position: 0,
        };
    }
};
exports.ScraperService = ScraperService;
exports.ScraperService = ScraperService = ScraperService_1 = __decorate([
    (0, common_1.Injectable)()
], ScraperService);
//# sourceMappingURL=scraper.service.js.map