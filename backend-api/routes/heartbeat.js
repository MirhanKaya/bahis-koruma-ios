const express = require('express');
const router  = express.Router();
const { recordHeartbeat, getStatus } = require('../services/heartbeatMonitor');

router.post('/', (req, res) => {
  recordHeartbeat();
  res.json({ success: true, timestamp: new Date().toISOString() });
});

router.get('/status', (req, res) => {
  res.json({ success: true, ...getStatus() });
});

module.exports = router;
