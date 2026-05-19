const express = require('express');
const router  = express.Router();

let nextId = 4;

const tickets = [
  {
    id: 't001',
    userId:   'user_demo_1',
    type:     'complaint',
    title:    'VPN bağlantısı bazen kopuyor',
    message:  'Uygulama arka planda çalışırken VPN tüneli zaman zaman kendi kendine kesiliyor. iPhone 14 Pro, iOS 17.4.',
    status:   'open',
    date:     '2026-05-18',
  },
  {
    id: 't002',
    userId:   'user_demo_2',
    type:     'complaint',
    title:    'Beyaz liste çalışmıyor',
    message:  'Beyaz listeye eklediğim siteye hâlâ bloke uygulanıyor. Uygulamayı tamamen kapatıp açmadan düzelmiyor.',
    status:   'open',
    date:     '2026-05-17',
  },
  {
    id: 't003',
    userId:   'user_demo_3',
    type:     'suggestion',
    title:    'Örnek öneri renk tablosu',
    message:  'Admin panelindeki grafiklerin renk uyumu ve buton tasarımları için neon yeşil yerine cyberpunk moru denenebilir.',
    status:   'reviewing',
    date:     '2026-05-16',
  },
];

router.get('/', (req, res) => {
  res.json({ success: true, tickets });
});

router.post('/', (req, res) => {
  const { userId, type, title, message } = req.body || {};
  if (!title || !message) {
    return res.status(400).json({ success: false, error: 'Başlık ve mesaj zorunlu' });
  }
  const now    = new Date();
  const date   = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`;
  const ticket = {
    id:      `t${String(nextId++).padStart(3,'0')}`,
    userId:  userId || 'anonymous',
    type:    type === 'suggestion' ? 'suggestion' : 'complaint',
    title:   String(title).trim(),
    message: String(message).trim(),
    status:  'open',
    date,
  };
  tickets.push(ticket);
  console.log(`[tickets] Yeni talep: #${ticket.id} — "${ticket.title}" (${ticket.type})`);
  res.status(201).json({ success: true, ticket });
});

router.post('/resolve', (req, res) => {
  const { ticketId } = req.body || {};
  const t = tickets.find(x => x.id === ticketId);
  if (!t) return res.status(404).json({ success: false, error: `Talep bulunamadı: ${ticketId}` });
  t.status = 'resolved';
  console.log(`[tickets] Çözüldü: #${t.id} — "${t.title}"`);
  res.json({ success: true, ticketId: t.id, newStatus: 'resolved' });
});

module.exports = router;
