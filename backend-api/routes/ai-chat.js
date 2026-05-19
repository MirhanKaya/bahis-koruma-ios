const express = require('express');
const router  = express.Router();

// In-memory chat log — all sessions stored here for admin panel monitoring
const chatLog = [];

const RESPONSES = [
  {
    keywords: ['vpn', 'bağlan', 'bağlantı', 'kesildi', 'koptu', 'çalışmıyor', 'açılmıyor'],
    reply: (msg) => `🔒 **VPN sorununu anlıyorum.** Birkaç adımı dene:\n\n1. Uygulamayı tamamen kapat ve yeniden aç.\n2. iOS Ayarlar → VPN → Profili sil → Uygulama üzerinden yeniden kur.\n3. Farklı bir Wi-Fi veya mobil veri ile dene.\n\nSorun devam ederse "Destek Talebi" aç, ekibimiz 2 saat içinde yanıtlar. 💪`,
  },
  {
    keywords: ['kumar', 'bahis', 'oynamak', 'isteği', 'gir', 'girme', 'bırak', 'bırakamıyor', 'yardım'],
    reply: (msg) => `💙 **Seni duyuyorum ve buradayım.**\n\nKumar isteği hissetmek çok zor, ama bu isteğin seni değil — hastalığın bir belirtisi.\n\n✨ Şu an yapabileceğin en güçlü şey: Kalkanını açık tut ve "SOS Gönder" butonuna bas. Güvenilir yakının anında haberdar olacak.\n\n🛡️ Her geçen gün koruma altında geçirdiğin bir kazanımdır. Gurur duy.`,
  },
  {
    keywords: ['bağımlılık', 'kurtulmak', 'destek', 'tedavi', 'terapi', 'psikolog'],
    reply: (msg) => `🌱 **Yardım istemek cesaret ister — ve sen o cesareti gösteriyorsun.**\n\nBir sonraki adım için:\n• 182 numaralı ALO Psikiyatri Hattı (ücretsiz)\n• Yakınınıza bugün söyle — yalnız olmadığını hissedeceksin\n• Uygulamadaki "Buddy SOS" özelliğini aktif et\n\nBiz her gün seninleyiz. 💚`,
  },
  {
    keywords: ['kalkan', 'nasıl', 'çalışıyor', 'çalışır', 'engel', 'engelleme', 'dns'],
    reply: (msg) => `🛡️ **Kalkan Koruması nasıl çalışır?**\n\nBahis Koruma 3 katmanlı sistem kullanır:\n\n1. **DNS Filtresi** — Kumar sitelerini domain seviyesinde engeller\n2. **VPN Tüneli** — Tüm trafik güvenli sunucumuzdan geçer\n3. **Sabotaj Alarmı** — Uygulama silinirse anında uyarı gönderir\n\nBu üç katman birlikte çalışarak %99.7 engelleme başarısı sağlar.`,
  },
  {
    keywords: ['sabotaj', 'sil', 'silme', 'alarm', 'uyarı', 'bypass', 'atla'],
    reply: (msg) => `⚠️ **Sabotaj Koruması hakkında bilgi:**\n\nUygulamayı silmeye veya VPN profilini kaldırmaya çalışırsan:\n• Buddy'ne SMS + anlık bildirim gider\n• Yönetici panelinde "sabotaj uyarısı" oluşur\n• 10 saniye içinde alarm tetiklenir\n\nBu özellik, zor anlarda seni senin iyiliğin için korur. 🔐`,
  },
  {
    keywords: ['abonelik', 'ücret', 'fiyat', 'plan', 'ödeme', 'iptal', 'yenile'],
    reply: (msg) => `💳 **Abonelik işlemleri için:**\n\nAboneliğini yönetmek için iOS Ayarlar → Apple ID → Abonelikler yolunu kullan.\n\nYa da bu talep formunu doldur — destek ekibimiz en kısa sürede geri döner.\n\nMevcut planlar: Aylık ₺49.99 | 3 Aylık ₺129.99 | Yıllık ₺449.99`,
  },
  {
    keywords: ['teşekkür', 'sağol', 'güzel', 'harika', 'iyi', 'süper', 'mükemmel'],
    reply: (msg) => `😊 **Rica ederim!** Seninle çalışmak güzel.\n\nBahis Koruma ailesi olarak her zaman yanındayız. Başka sorun veya merakın olursa çekinme, buradayım! 💙\n\nKorunmaya devam et. 🛡️`,
  },
];

const DEFAULT_REPLY = (msg) =>
  `🤖 **Bahis Koruma AI Asistanı**\n\nMesajını aldım! Şu an şunlarda yardımcı olabilirim:\n\n• 🔒 VPN bağlantı sorunları\n• 🛡️ Kalkan ve engelleme sistemi\n• 💙 Kumar isteği ve bağımlılık desteği\n• ⚠️ Sabotaj koruması\n• 💳 Abonelik yönetimi\n\nLütfen konunla ilgili biraz daha bilgi ver, sana özel yanıt hazırlayayım.`;

function getAIReply(message) {
  const lower = (message || '').toLowerCase();
  for (const rule of RESPONSES) {
    if (rule.keywords.some(k => lower.includes(k))) {
      return rule.reply(message);
    }
  }
  return DEFAULT_REPLY(message);
}

router.post('/', (req, res) => {
  const { userId, message, sessionId } = req.body || {};
  if (!message || !String(message).trim()) {
    return res.status(400).json({ success: false, error: 'Mesaj boş olamaz' });
  }
  const now       = new Date();
  const timestamp = now.toISOString();
  const reply     = getAIReply(message);

  const entry = {
    id:        `chat_${Date.now()}`,
    sessionId: sessionId || `session_${(userId || 'anon').slice(0,8)}`,
    userId:    userId || 'anonymous',
    userMsg:   String(message).trim(),
    botReply:  reply,
    timestamp,
    date:      `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`,
    time:      `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`,
  };
  chatLog.push(entry);

  console.log(`[ai-chat] ${entry.userId}: "${entry.userMsg.slice(0,50)}"`);
  res.json({ success: true, reply, entryId: entry.id });
});

router.get('/history', (req, res) => {
  res.json({ success: true, chats: chatLog.slice().reverse() });
});

module.exports = router;
