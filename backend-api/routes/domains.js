const express = require('express');
const router = express.Router();
const { readDomains, writeDomains, nextId } = require('../utils/storage');
const { classifyDomain } = require('../utils/classifier');

// GET /domains
router.get('/', (req, res) => {
  const domains = readDomains();
  res.json({
    success: true,
    count: domains.length,
    data: domains
  });
});

// POST /domains
// Body: { domain }
// Auto-classifies the domain using the same keyword logic as /classify-domain
router.post('/', (req, res) => {
  const { domain } = req.body;

  if (!domain || typeof domain !== 'string' || domain.trim() === '') {
    return res.status(400).json({ success: false, error: 'domain is required' });
  }

  const clean = domain.trim().toLowerCase();
  const domains = readDomains();

  const exists = domains.find(d => d.domain === clean);
  if (exists) {
    return res.status(409).json({ success: false, error: 'Domain already exists' });
  }

  const { category, isBlocked } = classifyDomain(clean);

  const newEntry = {
    id: nextId(domains),
    domain: clean,
    category,
    isBlocked,
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
