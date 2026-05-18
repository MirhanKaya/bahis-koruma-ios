const express = require('express');
const router  = express.Router();
const { readDomains, writeDomains, nextId } = require('../utils/storage');
const { classifyDomain }                    = require('../utils/classifier');
const {
  syncDomainToFirestore,
  deleteDomainFromFirestore,
} = require('../utils/firebase');

// GET /domains
// Returns all domains from local JSON storage.
// Mobile clients also subscribe to Firestore real-time snapshots separately.
router.get('/', (req, res) => {
  const domains = readDomains();
  res.json({ success: true, count: domains.length, data: domains });
});

// POST /domains
// Body: { domain: string }
// 1. Validates + deduplicates
// 2. Auto-classifies (keyword classifier)
// 3. Persists to local JSON
// 4. Syncs to Firestore (non-blocking — response is not delayed)
router.post('/', async (req, res) => {
  const { domain } = req.body;

  if (!domain || typeof domain !== 'string' || domain.trim() === '') {
    return res.status(400).json({ success: false, error: 'domain is required' });
  }

  const clean   = domain.trim().toLowerCase();
  const domains = readDomains();
  const exists  = domains.find(d => d.domain === clean);

  if (exists) {
    return res.status(409).json({ success: false, error: 'Domain already exists' });
  }

  const { category, isBlocked } = classifyDomain(clean);

  const newEntry = {
    id       : nextId(domains),
    domain   : clean,
    category,
    isBlocked,
    createdAt: new Date().toISOString(),
  };

  domains.push(newEntry);
  writeDomains(domains);

  // Firestore sync — fire-and-forget, never blocks or throws to the client
  syncDomainToFirestore(newEntry).catch(err =>
    console.warn('[domains] Firestore sync failed (POST):', err.message)
  );

  res.status(201).json({ success: true, data: newEntry });
});

// DELETE /domains/:id
// 1. Removes from local JSON
// 2. Removes matching document from Firestore (non-blocking)
router.delete('/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);

  if (isNaN(id)) {
    return res.status(400).json({ success: false, error: 'Invalid id' });
  }

  const domains = readDomains();
  const index   = domains.findIndex(d => d.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Domain not found' });
  }

  const removed = domains.splice(index, 1)[0];
  writeDomains(domains);

  // Firestore sync — fire-and-forget
  deleteDomainFromFirestore(removed.domain).catch(err =>
    console.warn('[domains] Firestore sync failed (DELETE):', err.message)
  );

  res.json({ success: true, data: removed });
});

module.exports = router;
