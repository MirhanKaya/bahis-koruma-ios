const express = require('express');
const path = require('path');
const http = require('http');

const app = express();
const PORT = 5000;
const BACKEND = 'http://127.0.0.1:8000';

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Backend proxy ─────────────────────────────────────────────────────────────
// Browser cannot reach 127.0.0.1:8000 directly through Replit's preview proxy.
// All /api/* calls from the frontend come here, and this server forwards them
// to the backend running on the same machine at port 8000.

function proxyRequest(req, res, backendPath, method, body) {
  const url = new URL(backendPath, BACKEND);
  const options = {
    hostname: '127.0.0.1',
    port: 8000,
    path: url.pathname,
    method: method || req.method,
    headers: { 'Content-Type': 'application/json' }
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.status(proxyRes.statusCode);
    let data = '';
    proxyRes.on('data', chunk => { data += chunk; });
    proxyRes.on('end', () => {
      try {
        res.json(JSON.parse(data));
      } catch {
        res.send(data);
      }
    });
  });

  proxyReq.on('error', () => {
    res.status(502).json({ success: false, error: 'Backend API ulaşılamıyor (port 8000)' });
  });

  if (body) {
    proxyReq.write(typeof body === 'string' ? body : JSON.stringify(body));
  }
  proxyReq.end();
}

app.get('/api/health',          (req, res) => proxyRequest(req, res, '/health'));
app.get('/api/domains',         (req, res) => proxyRequest(req, res, '/domains'));
app.post('/api/domains',        (req, res) => proxyRequest(req, res, '/domains',          'POST', req.body));
app.delete('/api/domains/:id',  (req, res) => proxyRequest(req, res, `/domains/${req.params.id}`, 'DELETE'));
app.post('/api/classify-domain',(req, res) => proxyRequest(req, res, '/classify-domain',  'POST', req.body));

// ── Frontend ──────────────────────────────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[admin] Panel running on http://0.0.0.0:${PORT}`);
  console.log(`[admin] Proxying API requests to ${BACKEND}`);
});
