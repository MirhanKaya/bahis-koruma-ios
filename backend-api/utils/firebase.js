/**
 * firebase.js
 *
 * Firebase Admin SDK service for the Bahis Koruma backend.
 *
 * Graceful fallback: if `firebase-service-account.json` is not present
 * (Firebase project not yet configured), all exports become no-ops and the
 * backend continues running with local JSON storage only.
 *
 * To activate:
 *   1. Create a Firebase project at https://console.firebase.google.com
 *   2. Project Settings → Service Accounts → Generate new private key
 *   3. Save the downloaded JSON as backend-api/firebase-service-account.json
 *   4. Restart the backend — Firestore sync activates automatically
 */

const path = require('path');
const fs   = require('fs');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, '../firebase-service-account.json');
const DOMAINS_COLLECTION   = 'domains';

// ── Lazy singleton ────────────────────────────────────────────────────────────

let _admin       = null;
let _db          = null;
let _initialized = false;
let _available   = false;

function _init() {
  if (_initialized) return;
  _initialized = true;

  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.log('[firebase] firebase-service-account.json not found — Firestore sync disabled');
    return;
  }

  try {
    _admin = require('firebase-admin');

    if (!_admin.apps.length) {
      const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));
      _admin.initializeApp({
        credential: _admin.credential.cert(serviceAccount),
      });
    }

    _db        = _admin.firestore();
    _available = true;
    console.log('[firebase] Firestore connected — domain sync active');
  } catch (err) {
    console.warn('[firebase] Initialization failed, continuing without Firestore:', err.message);
  }
}

function getDb() {
  _init();
  return _db;
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Returns true when Firebase Admin was initialized successfully.
 * Use this to conditionally show Firestore-dependent features.
 */
function isAvailable() {
  _init();
  return _available;
}

/**
 * Writes (or overwrites) a domain document to Firestore.
 * Document ID = domain name (e.g. "bet365.com") for easy client-side lookup.
 *
 * Firestore schema for each document in the `domains` collection:
 *   domainName  : String    — "bet365.com"
 *   category    : String    — "Kumar" | "Bilinmiyor"
 *   status      : String    — "Engellendi" | "İzin Verildi"
 *   isBlocked   : Boolean
 *   localId     : Number    — numeric ID from local JSON storage
 *   createdAt   : Timestamp
 */
async function syncDomainToFirestore(domain) {
  const db = getDb();
  if (!db) return null;

  try {
    const docData = {
      domainName : domain.domain,
      category   : domain.category === 'gambling' ? 'Kumar' : 'Bilinmiyor',
      status     : domain.isBlocked ? 'Engellendi' : 'İzin Verildi',
      isBlocked  : domain.isBlocked,
      localId    : domain.id,
      createdAt  : _admin.firestore.Timestamp.fromDate(new Date(domain.createdAt)),
    };

    await db.collection(DOMAINS_COLLECTION).doc(domain.domain).set(docData);
    return domain.domain;
  } catch (err) {
    console.warn('[firebase] syncDomain error:', err.message);
    return null;
  }
}

/**
 * Deletes a domain document from Firestore.
 * @param {string} domainName  e.g. "bet365.com"
 */
async function deleteDomainFromFirestore(domainName) {
  const db = getDb();
  if (!db) return;

  try {
    await db.collection(DOMAINS_COLLECTION).doc(domainName).delete();
  } catch (err) {
    console.warn('[firebase] deleteDomain error:', err.message);
  }
}

/**
 * Seeds Firestore with the current local JSON domain list.
 * Useful for one-time migration after connecting Firebase for the first time.
 * Called automatically on server startup when Firestore is available and empty.
 */
async function seedFirestoreFromLocalIfEmpty(localDomains) {
  const db = getDb();
  if (!db || !localDomains.length) return;

  try {
    const existing = await db.collection(DOMAINS_COLLECTION).limit(1).get();
    if (!existing.empty) return; // Already has data — skip seed

    const batch = db.batch();
    for (const d of localDomains) {
      const ref = db.collection(DOMAINS_COLLECTION).doc(d.domain);
      batch.set(ref, {
        domainName : d.domain,
        category   : d.category === 'gambling' ? 'Kumar' : 'Bilinmiyor',
        status     : d.isBlocked ? 'Engellendi' : 'İzin Verildi',
        isBlocked  : d.isBlocked,
        localId    : d.id,
        createdAt  : _admin.firestore.Timestamp.fromDate(new Date(d.createdAt)),
      });
    }
    await batch.commit();
    console.log(`[firebase] Seeded ${localDomains.length} domains to Firestore`);
  } catch (err) {
    console.warn('[firebase] Seed error:', err.message);
  }
}

module.exports = {
  isAvailable,
  getDb,
  syncDomainToFirestore,
  deleteDomainFromFirestore,
  seedFirestoreFromLocalIfEmpty,
  DOMAINS_COLLECTION,
};
