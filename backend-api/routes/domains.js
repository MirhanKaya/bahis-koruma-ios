const express = require('express');
const router = express.Router();
const { readDomains, writeDomains, nextId } = require('../utils/storage');

// GET /domains
// Returns all domains
router.get('/', (req, res) => {
  const domains = readDomains();
  res.json({
    success: true,
    count: domains.length,
    data: domains
  });
});

// POST /domains
// Body: { domain, category? }
router.post('/', (req, res) => {
  const { domain, category = 'unknown' } = req.body;

  if (!domain || typeof domain !== 'string' || domain.trim() === '') {
    return res.status(400).json({ success: false, error: 'domain is required' });
  }

  const clean = domain.trim().toLowerCase();
  const domains = readDomains();

  const exists = domains.find(d => d.domain === clean);
  if (exists) {
    return res.status(409).json({ success: false, error: 'Domain already exists' });
  }

  const newEntry = {
    id: nextId(domains),
    domain: clean,
    category,
    isBlocked: true,
    createdAt: new Date().toISOString()
  };

  domains.push(newEntry);
  writeDomains(domains);

  res.status(201).json({ success: true, data: newEntry });
});

// DELETE /domains/:id
router.delete('/:id', (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    return res.status(400).json({ success: false, error: 'Invalid id' });
  }

  const domains = readDomains();
  const index = domains.findIndex(d => d.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Domain not found' });
  }

  const removed = domains.splice(index, 1)[0];
  writeDomains(domains);

  res.json({ success: true, data: removed });
});

module.exports = router;
