const ROLE_PERMISSIONS = {
  subscriptions: ['super_admin', 'customer_support'],
  finance:       ['super_admin', 'technical_support'],
};

function requireRole(resource) {
  const allowedRoles = ROLE_PERMISSIONS[resource] || [];
  return (req, res, next) => {
    const raw  = req.headers['x-admin-role'] || 'super_admin';
    const role = raw.toLowerCase().replace(/-/g, '_');

    if (!allowedRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        error: 'Bu kaynağa erişim yetkiniz bulunmuyor.',
        resource,
        required: allowedRoles,
        current: role
      });
    }

    req.adminRole = role;
    next();
  };
}

module.exports = { requireRole };
