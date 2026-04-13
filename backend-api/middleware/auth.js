const API_KEYS = new Set([
  'test123',
  'bahis-koruma-admin-2026',
]);

function requireApiKey(req, res, next) {
  const key = req.headers['x-api-key'];

  if (!key || !API_KEYS.has(key)) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: invalid or missing API key'
    });
  }

  next();
}

module.exports = { requireApiKey };
