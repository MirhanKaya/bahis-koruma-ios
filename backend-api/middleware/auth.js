const { findByApiKey, isExpired } = require('../utils/users');

function requireApiKey(req, res, next) {
  const key = req.headers['x-api-key'];

  if (!key) {
    return res.status(401).json({
      success: false,
      error: 'Invalid API key'
    });
  }

  const user = findByApiKey(key);

  if (!user) {
    return res.status(401).json({
      success: false,
      error: 'Invalid API key'
    });
  }

  if (isExpired(user)) {
    return res.status(403).json({
      success: false,
      error: 'Subscription expired'
    });
  }

  req.user = user;
  next();
}

module.exports = { requireApiKey };
