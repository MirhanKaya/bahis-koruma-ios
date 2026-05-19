const express = require('express');
const router  = express.Router();
const { recordHeartbeat, getStatus } = require('../services/heartbeatMonitor');
const { recordUser, getActiveUsers } = require('../services/userTracker');

router.post('/', (req, res) => {
  recordHeartbeat();
  const { userId, device, location, shieldActive } = req.body || {};
  recordUser({
    userId:      userId || 'unknown',
    device:      device || 'Bilinmiyor',
    location:    location || 'Bilinmiyor',
    shieldActive: shieldActive !== false,
    ip:          req.headers['x-forwarded-for'] || req.socket.remoteAddress || '—'
  });
  res.json({ success: true, timestamp: new Date().toISOString() });
});

router.get('/status', (req, res) => {
  res.json({ success: true, ...getStatus() });
});

router.get('/users', (req, res) => {
  res.json({ success: true, users: getActiveUsers(), timestamp: new Date().toISOString() });
});

module.exports = router;
