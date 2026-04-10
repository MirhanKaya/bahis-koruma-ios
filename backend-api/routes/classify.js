const express = require('express');
const router = express.Router();

const GAMBLING_KEYWORDS = [
  'bet', 'bahis', 'casino', 'slot', 'poker',
  'kumar', 'jackpot', 'lottery', 'gambling',
  'rulet', 'tombala', 'şans', 'bets', 'spin',
  'wager', 'odds', 'blackjack', 'roulette'
];

// POST /classify-domain
// Body: { domain }
router.post('/', (req, res) => {
  const { domain } = req.body;

  if (!domain || typeof domain !== 'string' || domain.trim() === '') {
    return res.status(400).json({ success: false, error: 'domain is required' });
  }

  const clean = domain.trim().toLowerCase();
  const matchedKeywords = GAMBLING_KEYWORDS.filter(kw => clean.includes(kw));
  const isGambling = matchedKeywords.length > 0;

  res.json({
    success: true,
    domain: clean,
    category: isGambling ? 'gambling' : 'unknown',
    isBlocked: isGambling,
    matchedKeywords,
    confidence: isGambling ? Math.min(0.7 + matchedKeywords.length * 0.1, 0.99) : 0.05
  });
});

module.exports = router;
