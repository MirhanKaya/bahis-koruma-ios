const express = require('express');
const router  = express.Router();

router.post('/', (req, res) => {
  const {
    userName   = 'Kullanıcı',
    buddyName  = 'Arkadaş',
    buddyPhone = 'Bilinmiyor',
    type       = 'SOS',
    message    = null
  } = req.body;

  if (type === 'SHUTDOWN_ATTEMPT') {
    console.log(
      `🔴 SABOTAJ UYARISI: ${userName} koruma kalkanını KAPATTI!` +
      ` ${buddyName} (${buddyPhone}) kişisine bildirim gönderildi.`
    );
  } else if (type === 'APP_DELETED') {
    console.log(
      `🚨 KRİTİK ALARM: Uygulama Silindi veya Cihaz Bağlantısı Koptu!` +
      ` ${buddyName} (${buddyPhone}) kişisine acil alarm gönderildi.`
    );
  } else {
    console.log(
      `🚨 KRİZ UYARISI: ${userName} yardım istedi!` +
      ` ${buddyName} (${buddyPhone}) kişisine uyarı gönderildi.`
    );
  }

  if (message) console.log(`   Mesaj: ${message}`);

  res.json({ success: true, message: 'Buddy alert sent', type, buddyName, buddyPhone });
});

module.exports = router;
