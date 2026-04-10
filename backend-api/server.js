const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 8000;

app.use(cors());
app.use(express.json());

let domains = [
  { id: 1, domain: 'bahis.com', category: 'gambling', status: 'blocked', addedAt: new Date().toISOString() },
  { id: 2, domain: 'casino.net', category: 'gambling', status: 'blocked', addedAt: new Date().toISOString() },
  { id: 3, domain: 'bet365.com', category: 'gambling', status: 'blocked', addedAt: new Date().toISOString() },
];
let nextId = 4;

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/domains', (req, res) => {
  res.json({ success: true, data: domains, total: domains.length });
});

app.post('/api/domains', (req, res) => {
  const { domain, category = 'gambling' } = req.body;
  if (!domain) {
    return res.status(400).json({ success: false, error: 'Domain is required' });
  }
  const existing = domains.find(d => d.domain === domain);
  if (existing) {
    return res.status(409).json({ success: false, error: 'Domain already exists' });
  }
  const newDomain = { id: nextId++, domain, category, status: 'blocked', addedAt: new Date().toISOString() };
  domains.push(newDomain);
  res.status(201).json({ success: true, data: newDomain });
});

app.delete('/api/domains/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const index = domains.findIndex(d => d.id === id);
  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Domain not found' });
  }
  domains.splice(index, 1);
  res.json({ success: true, message: 'Domain removed' });
});

app.post('/api/classify', (req, res) => {
  const { domain } = req.body;
  if (!domain) {
    return res.status(400).json({ success: false, error: 'Domain is required' });
  }
  const gamblingKeywords = ['bet', 'casino', 'poker', 'slot', 'bahis', 'kumar', 'jackpot', 'lottery', 'gambling'];
  const isGambling = gamblingKeywords.some(kw => domain.toLowerCase().includes(kw));
  res.json({
    success: true,
    domain,
    isGambling,
    confidence: isGambling ? 0.92 : 0.08,
    category: isGambling ? 'gambling' : 'safe'
  });
});

app.get('/api/stats', (req, res) => {
  res.json({
    success: true,
    data: {
      totalDomains: domains.length,
      blockedDomains: domains.filter(d => d.status === 'blocked').length,
      categories: { gambling: domains.length }
    }
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend API running on port ${PORT}`);
});
