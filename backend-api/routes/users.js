const express = require('express');
const router = express.Router();
const { findByEmail, createUser, updateUserPlan, PLAN_DURATIONS } = require('../utils/users');

// POST /register-api-user
// Body: { email }
// Creates a new trial user or returns existing one
router.post('/register-api-user', (req, res) => {
  const { email } = req.body;

  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ success: false, error: 'Valid email is required' });
  }

  const existing = findByEmail(email);
  if (existing) {
    return res.json({ success: true, isNew: false, data: existing });
  }

  const user = createUser(email);
  res.status(201).json({ success: true, isNew: true, data: user });
});

// POST /admin/set-plan
// Body: { email, plan }
// Plans: trial (7d), pro_6 (180d), pro_12 (365d)
router.post('/admin/set-plan', (req, res) => {
  const { email, plan } = req.body;

  if (!email || !plan) {
    return res.status(400).json({ success: false, error: 'email and plan are required' });
  }

  if (!PLAN_DURATIONS[plan]) {
    return res.status(400).json({
      success: false,
      error: `Invalid plan. Valid plans: ${Object.keys(PLAN_DURATIONS).join(', ')}`
    });
  }

  const user = updateUserPlan(email, plan);
  if (!user) {
    return res.status(404).json({ success: false, error: 'User not found' });
  }

  res.json({ success: true, data: user });
});

module.exports = router;
