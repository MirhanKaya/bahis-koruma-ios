const TIMEOUT_MS = 15000;

const users = new Map();

function recordUser({ userId, device, location, shieldActive, ip, savedMoney, cleanDays }) {
  if (!userId) return;
  const prev       = users.get(userId) || {};
  const prevShield = prev.shieldActive !== undefined ? prev.shieldActive : true;
  const nowSabotage = prev.sabotage || (prevShield && shieldActive === false);

  users.set(userId, {
    userId,
    device:       device      || prev.device   || 'Bilinmiyor',
    location:     location    || prev.location || 'Bilinmiyor',
    shieldActive: shieldActive !== false,
    lastSeen:     Date.now(),
    ip:           ip          || prev.ip       || '—',
    sabotage:     nowSabotage,
    savedMoney:   savedMoney  != null ? parseFloat(savedMoney) : (prev.savedMoney || 0),
    cleanDays:    cleanDays   != null ? parseInt(cleanDays)    : (prev.cleanDays  || 0),
  });
}

function getActiveUsers() {
  const now    = Date.now();
  const result = [];

  for (const u of users.values()) {
    const ageSec = Math.floor((now - u.lastSeen) / 1000);
    const online = ageSec < TIMEOUT_MS / 1000;

    let status;
    if (!online) {
      status = 'offline';
    } else if (u.sabotage || !u.shieldActive) {
      status = 'sabotage';
    } else {
      status = 'active';
    }

    const lastSeenLabel = ageSec < 3   ? 'az önce'
                        : ageSec < 60  ? `${ageSec}sn önce`
                        : ageSec < 120 ? '1dk önce'
                        :                `${Math.floor(ageSec / 60)}dk önce`;

    result.push({ ...u, online, ageSec, lastSeenLabel, status });
  }

  result.sort((a, b) => {
    const order = { sabotage: 0, offline: 1, active: 2 };
    if (order[a.status] !== order[b.status]) return order[a.status] - order[b.status];
    return b.lastSeen - a.lastSeen;
  });

  return result;
}

module.exports = { recordUser, getActiveUsers };
