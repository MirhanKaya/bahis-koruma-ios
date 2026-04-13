const express = require('express');
const router = express.Router();
const { classifyDomain } = require('../utils/classifier');

// POST /classify-domain
// Body: { domain }
router.post('/', (req, res) => {
  const { domain } = req.body;

  if (!domain || typeof domain !== 'string' || domain.trim() === '') {
    return res.status(400).json({ success: false, error: 'domain is required' });
  }

  const clean = domain.trim().toLowerCase();
  const result = classifyDomain(clean);

  res.json({
    success: true,
    domain: clean,
    ...result
  });
});

module.exports = router;
