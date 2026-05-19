const express = require('express');
const router  = express.Router();

const subscriptions = [
  { id:'u001', name:'Ahmet Kaya',     device:'iPhone 14 Pro',    daysLeft:14, status:'active',    refCode:'REF-AK14',  plan:'Aylık',   amount:49.99,  startDate:'2026-05-05', packageType:'family'  },
  { id:'u002', name:'Mehmet Yıldız',  device:'iPhone 15',         daysLeft:0,  status:'expired',   refCode:'REF-MY15',  plan:'Aylık',   amount:49.99,  startDate:'2026-04-19', packageType:'single'  },
  { id:'u003', name:'Fatma Şahin',    device:'iPhone 13',         daysLeft:28, status:'active',    refCode:'REF-FS13',  plan:'3 Aylık', amount:129.99, startDate:'2026-04-21', packageType:'family'  },
  { id:'u004', name:'Ali Demir',      device:'iPhone 15 Pro Max', daysLeft:7,  status:'suspended', refCode:'REF-AD15',  plan:'Aylık',   amount:49.99,  startDate:'2026-05-12', packageType:'couple'  },
  { id:'u005', name:'Zeynep Arslan',  device:'iPhone 14',         daysLeft:60, status:'active',    refCode:'REF-ZA14',  plan:'6 Aylık', amount:249.99, startDate:'2026-03-19', packageType:'family'  },
  { id:'u006', name:'Hasan Çelik',    device:'iPhone 12',         daysLeft:0,  status:'expired',   refCode:'REF-HC12',  plan:'Aylık',   amount:49.99,  startDate:'2026-04-01', packageType:'single'  },
  { id:'u007', name:'Ayşe Koca',      device:'iPhone 15 Plus',    daysLeft:45, status:'active',    refCode:'REF-AK15P', plan:'3 Aylık', amount:129.99, startDate:'2026-04-04', packageType:'couple'  },
  { id:'u008', name:'Mustafa Yurt',   device:'iPhone 13 Mini',    daysLeft:3,  status:'active',    refCode:'REF-MY13',  plan:'Aylık',   amount:49.99,  startDate:'2026-04-16', packageType:'single'  },
  { id:'u009', name:'Selin Kaya',     device:'iPhone 14 Plus',    daysLeft:90, status:'active',    refCode:'REF-SK14P', plan:'Yıllık',  amount:449.99, startDate:'2026-02-18', packageType:'family'  },
  { id:'u010', name:'Burak Erdoğan',  device:'iPhone 15 Pro',     daysLeft:0,  status:'suspended', refCode:'REF-BE15',  plan:'Aylık',   amount:49.99,  startDate:'2026-05-01', packageType:'couple'  },
];

const MAX_FAMILY_MEMBERS = 5;

const familyMembers = {
  'u001': [
    { id:'fm-001-1', name:'Eş',      shieldActive:true  },
    { id:'fm-001-2', name:'Çocuk 1', shieldActive:true  },
    { id:'fm-001-3', name:'Çocuk 2', shieldActive:false },
  ],
  'u003': [
    { id:'fm-003-1', name:'Eş',      shieldActive:true },
    { id:'fm-003-2', name:'Çocuk 1', shieldActive:true },
  ],
  'u005': [
    { id:'fm-005-1', name:'Eş',      shieldActive:true  },
    { id:'fm-005-2', name:'Anne',    shieldActive:true  },
    { id:'fm-005-3', name:'Çocuk 1', shieldActive:true  },
    { id:'fm-005-4', name:'Çocuk 2', shieldActive:false },
  ],
  'u009': [
    { id:'fm-009-1', name:'Eş',      shieldActive:true  },
    { id:'fm-009-2', name:'Çocuk 1', shieldActive:true  },
    { id:'fm-009-3', name:'Çocuk 2', shieldActive:true  },
    { id:'fm-009-4', name:'Çocuk 3', shieldActive:true  },
    { id:'fm-009-5', name:'Anne',    shieldActive:false },
  ],
  'SIM-Kullanici-001': [
    { id:'fm-sim-1', name:'Eş',      shieldActive:true  },
    { id:'fm-sim-2', name:'Çocuk 1', shieldActive:true  },
    { id:'fm-sim-3', name:'Çocuk 2', shieldActive:false },
  ],
};

router.get('/', (req, res) => {
  res.json({ success: true, subscriptions, total: subscriptions.length });
});

router.post('/toggle-status', (req, res) => {
  const { userId } = req.body || {};
  const user = subscriptions.find(u => u.id === userId);
  if (!user) return res.status(404).json({ success: false, error: `Kullanıcı bulunamadı: ${userId}` });
  user.status = user.status === 'active' ? 'suspended' : 'active';
  console.log(`[subscriptions] ${user.name} → ${user.status}`);
  res.json({ success: true, userId: user.id, newStatus: user.status, name: user.name });
});

router.get('/family/:userId', (req, res) => {
  const { userId } = req.params;
  const user = subscriptions.find(u => u.id === userId);
  const isSim = userId === 'SIM-Kullanici-001';
  if (!user && !isSim) return res.status(404).json({ success: false, error: 'Kullanıcı bulunamadı' });
  if (user && user.packageType !== 'family' && !isSim) {
    return res.status(400).json({ success: false, error: 'Bu kullanıcı Family Plan kullanmıyor' });
  }
  const members = familyMembers[userId] || [];
  res.json({ success: true, userId, members, total: members.length, maxAllowed: MAX_FAMILY_MEMBERS });
});

router.post('/family/add', (req, res) => {
  const { userId, name } = req.body || {};
  if (!userId || !name || !name.trim()) {
    return res.status(400).json({ success: false, error: 'userId ve name zorunludur' });
  }
  const trimmedName = name.trim();
  if (!familyMembers[userId]) familyMembers[userId] = [];
  const members = familyMembers[userId];
  if (members.length >= MAX_FAMILY_MEMBERS) {
    return res.status(400).json({
      success: false,
      error: `Maksimum ${MAX_FAMILY_MEMBERS} üye sınırına ulaşıldı`,
      limitReached: true,
      current: members.length,
      max: MAX_FAMILY_MEMBERS,
    });
  }
  const newMember = {
    id:          `fm-${userId}-${Date.now()}`,
    name:        trimmedName,
    shieldActive: true,
  };
  members.push(newMember);
  console.log(`[family] ${userId} → "${trimmedName}" eklendi (${members.length}/${MAX_FAMILY_MEMBERS})`);
  res.json({ success: true, member: newMember, total: members.length, maxAllowed: MAX_FAMILY_MEMBERS });
});

router.delete('/family/remove', (req, res) => {
  const { userId, memberId } = req.body || {};
  if (!userId || !memberId) return res.status(400).json({ success: false, error: 'userId ve memberId zorunludur' });
  const members = familyMembers[userId];
  if (!members) return res.status(404).json({ success: false, error: 'Kullanıcı bulunamadı' });
  const idx = members.findIndex(m => m.id === memberId);
  if (idx === -1) return res.status(404).json({ success: false, error: 'Üye bulunamadı' });
  const [removed] = members.splice(idx, 1);
  console.log(`[family] ${userId} → "${removed.name}" silindi (${members.length}/${MAX_FAMILY_MEMBERS})`);
  res.json({ success: true, removed, total: members.length });
});

module.exports = router;
