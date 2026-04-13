const express = require('express');
const cors = require('cors');

const { requireApiKey } = require('./middleware/auth');
const domainsRouter   = require('./routes/domains');
const classifyRouter  = require('./routes/classify');

const app = express();

app.use(cors());
app.use(express.json());

// ── Public ─────────────────────────────────────────────────────────────────────
// /health is open — no API key required
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// ── Protected ──────────────────────────────────────────────────────────────────
// All routes below require a valid x-api-key header
app.use('/domains',         requireApiKey, domainsRouter);
app.use('/classify-domain', requireApiKey, classifyRouter);

// Legacy aliases (same protection)
app.use('/api/domains',  requireApiKey, domainsRouter);
app.use('/api/classify', requireApiKey, classifyRouter);

// ── 404 fallback ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, error: `Route not found: ${req.method} ${req.path}` });
});

module.exports = app;
