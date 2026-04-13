const GAMBLING_KEYWORDS = [
  'bet', 'bahis', 'casino', 'slot', 'poker',
  'kumar', 'jackpot', 'lottery', 'gambling',
  'rulet', 'tombala', 'şans', 'bets', 'spin',
  'wager', 'odds', 'blackjack', 'roulette'
];

function classifyDomain(domain) {
  const clean = domain.trim().toLowerCase();
  const matchedKeywords = GAMBLING_KEYWORDS.filter(kw => clean.includes(kw));
  const isGambling = matchedKeywords.length > 0;

  return {
    category: isGambling ? 'gambling' : 'unknown',
    isBlocked: isGambling,
    matchedKeywords,
    confidence: isGambling ? Math.min(0.7 + matchedKeywords.length * 0.1, 0.99) : 0.05
  };
}

module.exports = { classifyDomain };
