/**
 * domainScanner.js
 *
 * Simulates a background scraper that monitors newly registered domains
 * and automatically blocks gambling-related ones.
 *
 * In production this would be replaced with a real WHOIS/CT-log feed.
 * For now it cycles through a mock pool every 60 seconds, picks a random
 * batch of 3-5 "newly seen" domains, classifies them by keyword, and
 * adds any gambling domains that are not already in the local storage.
 */

const { readDomains, writeDomains, nextId } = require('../utils/storage');
const { isAvailable, getDb, DOMAINS_COLLECTION } = require('../utils/firebase');

// ── Keywords that flag a domain as gambling ────────────────────────────────────
const GAMBLING_KEYWORDS = ['bet', 'casino', 'slot', 'bahis', 'poker', 'rulet'];

// ── Mock pool — simulates a feed of newly registered domains ─────────────────
const MOCK_POOL = [
  'yeni-bahis99.com',
  'test-casino.net',
  'superbetting.io',
  'slot-oyunlari.com',
  'casino-bonus-tr.net',
  'bahis-tahmin.com',
  'live-bet.app',
  'rulet-oyna.net',
  'poker-club-tr.com',
  'bigslot.casino',
  'casinomega.net',
  'betking-tr.com',
  'bahismax.io',
  'slotworld.com.tr',
  'casino-vip-tr.net',
  'blog-sitesi.com',
  'haber-portali.net',
  'teknoloji-blog.com',
  'yemek-tarifleri.net',
  'spor-haberleri.com',
  'market-indirim.com',
  'online-egitim.net',
  'seyahat-rehberi.com',
  'finans-haberleri.com',
  'saglik-bilgi.net',
];

// Tracks domains already handled this session to avoid log spam across ticks
const _seenThisSession = new Set();

// ── Classifier ────────────────────────────────────────────────────────────────
function isGambling(domain) {
  const d = domain.toLowerCase();
  return GAMBLING_KEYWORDS.some(kw => d.includes(kw));
}

// ── Single scan tick ──────────────────────────────────────────────────────────
async function scanTick() {
  const domains = readDomains();
  const existingNames = new Set(domains.map(d => d.domain));

  // Pick a random batch of 3–5 domains from the pool each tick
  const shuffled = [...MOCK_POOL].sort(() => Math.random() - 0.5);
  const batch    = shuffled.slice(0, 3 + Math.floor(Math.random() * 3));

  const toAdd = [];

  for (const raw of batch) {
    const domain = raw.toLowerCase().trim();

    if (!isGambling(domain))   continue;  // benign domain — skip
    if (existingNames.has(domain)) continue;  // already in storage — skip
    if (_seenThisSession.has(domain)) continue; // added earlier this session — skip

    toAdd.push(domain);
    _seenThisSession.add(domain);
    existingNames.add(domain);  // prevent double-add within same tick
  }

  if (!toAdd.length) return;

  // ── Persist to local JSON ──────────────────────────────────────────────────
  const fresh = readDomains(); // re-read to avoid race conditions
  const added = [];

  for (const domain of toAdd) {
    if (fresh.find(d => d.domain === domain)) continue; // guard double-write

    const entry = {
      id       : nextId(fresh),
      domain,
      category : 'gambling',
      isBlocked: true,
      createdAt: new Date().toISOString(),
    };

    fresh.push(entry);
    added.push(entry);
  }

  if (!added.length) return;

  writeDomains(fresh);

  // ── Firestore sync (fire-and-forget) ──────────────────────────────────────
  if (isAvailable()) {
    const db    = getDb();
    const admin = require('firebase-admin');

    for (const entry of added) {
      const docData = {
        domainName : entry.domain,
        category   : 'Kumar',
        status     : 'Engellendi',
        isBlocked  : true,
        localId    : entry.id,
        createdAt  : admin.firestore.FieldValue.serverTimestamp(),
      };

      db.collection(DOMAINS_COLLECTION)
        .doc(entry.domain)
        .set(docData)
        .catch(err => console.warn('[scanner] Firestore write failed:', err.message));
    }
  }

  // ── Console output ────────────────────────────────────────────────────────
  for (const entry of added) {
    console.log(
      `🤖 OTOMASYON: Yeni kumar sitesi tespit edildi ve engellendi: ${entry.domain}`
    );
  }
}

// ── Public: start the scanner ─────────────────────────────────────────────────
function startDomainScanner(intervalMs = 60_000) {
  console.log(`[scanner] Domain tarayıcısı başlatıldı — tarama aralığı: ${intervalMs / 1000}s`);

  // Run once immediately so the first detection appears right on startup
  scanTick().catch(err => console.warn('[scanner] Tick error:', err.message));

  setInterval(() => {
    scanTick().catch(err => console.warn('[scanner] Tick error:', err.message));
  }, intervalMs);
}

module.exports = { startDomainScanner };
