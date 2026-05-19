const http = require('http');

let lastHeartbeat   = null;
let alarmFired      = false;
let monitorInterval = null;

function recordHeartbeat() {
  const wasAlarmed = alarmFired;
  lastHeartbeat = Date.now();
  alarmFired    = false;
  if (wasAlarmed) {
    console.log('💚 HEARTBEAT: Cihaz bağlantısı yeniden kuruldu.');
  }
}

function getStatus() {
  if (!lastHeartbeat) return { active: false, lastSeen: null, ageSec: null, alarmed: false };
  const age = Date.now() - lastHeartbeat;
  return {
    active:   age < 10000,
    lastSeen: new Date(lastHeartbeat).toISOString(),
    ageSec:   Math.floor(age / 1000),
    alarmed:  alarmFired
  };
}

function triggerCriticalAlarm() {
  console.log('🚨 KRİTİK ALARM: Uygulama Silindi veya Cihaz Bağlantısı Koptu!');
  console.log(`   Son heartbeat: ${Math.floor((Date.now() - lastHeartbeat) / 1000)}s önce`);

  const body = JSON.stringify({
    userName:  'SİSTEM-OTOMATİK',
    buddyName: 'Güvenilir Yakın',
    buddyPhone: 'Kayıtlı Numara',
    type:      'APP_DELETED',
    message:   '🚨 Uygulama Silindi veya Cihaz Bağlantısı Koptu!'
  });

  const options = {
    hostname: '127.0.0.1',
    port:     8000,
    path:     '/api/buddy/alert',
    method:   'POST',
    headers: {
      'Content-Type':   'application/json',
      'Content-Length': Buffer.byteLength(body),
      'x-api-key':      'bahis-koruma-admin-2026'
    }
  };

  const req = http.request(options);
  req.on('error', () => {});
  req.write(body);
  req.end();
}

function startHeartbeatMonitor() {
  if (monitorInterval) return;
  console.log('[heartbeat] Monitör başlatıldı — 10s zaman aşımı, 3s kontrol aralığı');

  monitorInterval = setInterval(() => {
    if (!lastHeartbeat) return;
    const age = Date.now() - lastHeartbeat;
    if (age > 10000 && !alarmFired) {
      alarmFired = true;
      triggerCriticalAlarm();
    }
  }, 3000);
}

module.exports = { recordHeartbeat, getStatus, startHeartbeatMonitor };
