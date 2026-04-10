const express = require('express');
const cors = require('cors');

const domainsRouter = require('./routes/domains');
const classifyRouter = require('./routes/classify');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Routes
app.use('/domains', domainsRouter);
app.use('/classify-domain', classifyRouter);

// Legacy aliases (admin panel compatibility)
app.use('/api/domains', domainsRouter);
app.use('/api/classify', classifyRouter);

// 404 fallback
app.use((req, res) => {
  res.status(404).json({ success: false, error: `Route not found: ${req.method} ${req.path}` });
});

module.exports = app;
