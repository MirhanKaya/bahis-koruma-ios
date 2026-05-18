const express = require('express');
const router  = express.Router();

router.post('/', (req, res) => {
  const {
    userName   = 'Kullanıcı',
    buddyName  = 'Arkadaş',
    buddyPhone = 'Bilinmiyor'
  } = req.body;

  console.log(
    `🚨 KRİZ UYARISI: ${userName} koruma kalkanını kapatma talebinde bulundu!` +
    ` ${buddyName} (${buddyPhone}) kişisine uyarı gönderildi.`
  );

  res.json({ success: true, message: 'Buddy alert sent', buddyName, buddyPhone });
});

module.exports = router;
