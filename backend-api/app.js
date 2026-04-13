const express = require('express');
const cors = require('cors');

const { requireApiKey } = require('./middleware/auth');
const domainsRouter  = require('./routes/domains');
const classifyRouter = require('./routes/classify');
const usersRouter    = require('./routes/users');

const app = express();

app.use(cors());
app.use(express.json());

// ── Public ─────────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// POST /register-api-user — open, creates a trial user
// POST /admin/set-plan    — open, for testing purposes
app.use('/', usersRouter);

// ── Protected ──────────────────────────────────────────────────────────────────
app.use('/domains',         requireApiKey, domainsRouter);
app.use('/classify-domain', requireApiKey, classifyRouter);

// Legacy aliases
app.use('/api/domains',  requireApiKey, domainsRouter);
app.use('/api/classify', requireApiKey, classifyRouter);

// ── 404 ────────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, error: `Route not found: ${req.method} ${req.path}` });
});

module.exports = app;
