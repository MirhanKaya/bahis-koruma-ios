const express = require('express');
const router  = express.Router();

const subscriptions = [
  { id: 'u001', name: 'Ahmet Kaya',     device: 'iPhone 14 Pro',     daysLeft: 14,  status: 'active',    refCode: 'REF-AK14',  plan: 'Aylık',   amount: 49.99,  startDate: '2026-05-05' },
  { id: 'u002', name: 'Mehmet Yıldız',  device: 'iPhone 15',          daysLeft: 0,   status: 'expired',   refCode: 'REF-MY15',  plan: 'Aylık',   amount: 49.99,  startDate: '2026-04-19' },
  { id: 'u003', name: 'Fatma Şahin',    device: 'iPhone 13',          daysLeft: 28,  status: 'active',    refCode: 'REF-FS13',  plan: '3 Aylık', amount: 129.99, startDate: '2026-04-21' },
  { id: 'u004', name: 'Ali Demir',      device: 'iPhone 15 Pro Max',  daysLeft: 7,   status: 'suspended', refCode: 'REF-AD15',  plan: 'Aylık',   amount: 49.99,  startDate: '2026-05-12' },
  { id: 'u005', name: 'Zeynep Arslan',  device: 'iPhone 14',          daysLeft: 60,  status: 'active',    refCode: 'REF-ZA14',  plan: '6 Aylık', amount: 249.99, startDate: '2026-03-19' },
  { id: 'u006', name: 'Hasan Çelik',    device: 'iPhone 12',          daysLeft: 0,   status: 'expired',   refCode: 'REF-HC12',  plan: 'Aylık',   amount: 49.99,  startDate: '2026-04-01' },
  { id: 'u007', name: 'Ayşe Koca',      device: 'iPhone 15 Plus',     daysLeft: 45,  status: 'active',    refCode: 'REF-AK15P', plan: '3 Aylık', amount: 129.99, startDate: '2026-04-04' },
  { id: 'u008', name: 'Mustafa Yurt',   device: 'iPhone 13 Mini',     daysLeft: 3,   status: 'active',    refCode: 'REF-MY13',  plan: 'Aylık',   amount: 49.99,  startDate: '2026-04-16' },
  { id: 'u009', name: 'Selin Kaya',     device: 'iPhone 14 Plus',     daysLeft: 90,  status: 'active',    refCode: 'REF-SK14P', plan: 'Yıllık',  amount: 449.99, startDate: '2026-02-18' },
  { id: 'u010', name: 'Burak Erdoğan',  device: 'iPhone 15 Pro',      daysLeft: 0,   status: 'suspended', refCode: 'REF-BE15',  plan: 'Aylık',   amount: 49.99,  startDate: '2026-05-01' },
];

router.get('/', (req, res) => {
  res.json({ success: true, subscriptions, total: subscriptions.length });
});

router.post('/toggle-status', (req, res) => {
  const { userId } = req.body || {};
  const user = subscriptions.find(u => u.id === userId);
  if (!user) {
    return res.status(404).json({ success: false, error: `Kullanıcı bulunamadı: ${userId}` });
  }
  user.status = user.status === 'active' ? 'suspended' : 'active';
  console.log(`[subscriptions] ${user.name} → ${user.status}`);
  res.json({ success: true, userId: user.id, newStatus: user.status, name: user.name });
});

module.exports = router;
