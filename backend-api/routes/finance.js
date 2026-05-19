const express = require('express');
const router  = express.Router();

const refunds = [
  { id: 'ref001', userId: 'u002', userName: 'Mehmet Yıldız', reason: 'Hizmet beğenilmedi',  amount: 49.99,  date: '2026-05-18', status: 'pending' },
  { id: 'ref002', userId: 'u010', userName: 'Burak Erdoğan', reason: 'Yanlış ödeme',        amount: 49.99,  date: '2026-05-17', status: 'pending' },
  { id: 'ref003', userId: 'u006', userName: 'Hasan Çelik',   reason: 'Teknik sorun',        amount: 49.99,  date: '2026-05-15', status: 'pending' },
];

const dailyRevenue = [
  { day: 'Pzt', amount: 149.97 },
  { day: 'Sal', amount: 49.99  },
  { day: 'Çar', amount: 249.99 },
  { day: 'Per', amount: 0      },
  { day: 'Cum', amount: 449.99 },
  { day: 'Cmt', amount: 129.99 },
  { day: 'Paz', amount: 49.99  },
];

router.get('/', (req, res) => {
  const pendingRefunds = refunds.filter(r => r.status === 'pending');
  res.json({
    success:          true,
    monthlyRevenue:   2847.50,
    totalRevenue:     14230.75,
    activeSubscribers: 6,
    pendingRefundCount: pendingRefunds.length,
    pendingRefunds,
    dailyRevenue,
  });
});

router.post('/refund/:id/approve', (req, res) => {
  const r = refunds.find(x => x.id === req.params.id);
  if (!r) return res.status(404).json({ success: false, error: 'Talep bulunamadı' });
  r.status = 'approved';
  console.log(`[finance] İade ONAYLANDI: ${r.userName} — ${r.amount} ₺`);
  res.json({ success: true, refundId: r.id, newStatus: 'approved' });
});

router.post('/refund/:id/reject', (req, res) => {
  const r = refunds.find(x => x.id === req.params.id);
  if (!r) return res.status(404).json({ success: false, error: 'Talep bulunamadı' });
  r.status = 'rejected';
  console.log(`[finance] İade REDDEDİLDİ: ${r.userName} — ${r.amount} ₺`);
  res.json({ success: true, refundId: r.id, newStatus: 'rejected' });
});

module.exports = router;
