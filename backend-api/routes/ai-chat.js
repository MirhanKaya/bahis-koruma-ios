const express = require('express');
const router  = express.Router();

const chatLog = [];

// ── Per-language response sets ───────────────────────────────────────────────
const LANG_RESPONSES = {
  tr: [
    { kw: ['vpn','bağlan','bağlantı','kesildi','koptu','çalışmıyor','açılmıyor'],
      r: () => `🔒 **VPN sorununu anlıyorum.** Birkaç adımı dene:\n\n1. Uygulamayı tamamen kapat ve yeniden aç.\n2. iOS Ayarlar → VPN → Profili sil → Uygulamadan yeniden kur.\n3. Farklı bir Wi-Fi veya mobil veri dene.\n\nSorun devam ederse Destek Talebi aç — ekibimiz 2 saat içinde yanıtlar. 💪` },
    { kw: ['kumar','bahis','oynamak','isteği','girme','bırak','bırakamıyor','yardım'],
      r: () => `💙 **Seni duyuyorum ve buradayım.**\n\nKumar isteği hissetmek çok zor, ama bu isteğin seni değil — hastalığın bir belirtisi.\n\n✨ Şu an en güçlü şey: Kalkanını açık tut, "SOS Gönder"e bas. Yakının anında haberdar olacak.\n\n🛡️ Koruma altında geçirdiğin her gün bir kazanımdır.` },
    { kw: ['bağımlılık','kurtulmak','destek','tedavi','terapi','psikolog'],
      r: () => `🌱 **Yardım istemek cesaret ister — ve sen o cesareti gösteriyorsun.**\n\n• 182 ALO Psikiyatri Hattı (ücretsiz)\n• Yakınınıza bugün söyle\n• "Buddy SOS" özelliğini aktif et\n\nBiz her gün seninleyiz. 💚` },
    { kw: ['kalkan','nasıl','engel','dns'],
      r: () => `🛡️ **3 katmanlı koruma sistemi:**\n\n1. **DNS Filtresi** — Kumar sitelerini domain seviyesinde engeller\n2. **VPN Tüneli** — Trafik güvenli sunucumuzdan geçer\n3. **Sabotaj Alarmı** — Uygulama silinirse anında uyarı\n\n%99.7 engelleme başarısı.` },
    { kw: ['sabotaj','sil','alarm','bypass'],
      r: () => `⚠️ Uygulamayı silmeye çalışırsan:\n• Buddy'ne SMS + bildirim gider\n• Yönetici panelinde uyarı oluşur\n• 10 sn içinde alarm tetiklenir 🔐` },
    { kw: ['abonelik','ücret','fiyat','ödeme','iptal'],
      r: () => `💳 iOS Ayarlar → Apple ID → Abonelikler yolunu kullan.\n\nPlanlar: Aylık ₺49.99 | 3 Aylık ₺129.99 | Yıllık ₺449.99` },
    { kw: ['teşekkür','sağol','harika','süper'],
      r: () => `😊 Rica ederim! Bahis Koruma ailesi olarak her zaman yanındayız. Korunmaya devam et. 🛡️` },
  ],
  en: [
    { kw: ['vpn','connect','connection','disconnect','not working','broken'],
      r: () => `🔒 **I understand your VPN issue.** Try these steps:\n\n1. Fully close and reopen the app.\n2. iOS Settings → VPN → Delete profile → Reinstall via app.\n3. Try a different Wi-Fi or mobile data.\n\nIf the issue persists, open a Support Ticket — our team responds within 2 hours. 💪` },
    { kw: ['gambl','casino','bet','betting','urge','help','quit','addiction'],
      r: () => `💙 **I hear you and I'm here.**\n\nFeeling the urge to gamble is incredibly hard — but it's the illness speaking, not you.\n\n✨ The strongest thing you can do right now: Keep your Shield on and press "Send SOS". Your trusted contact will be notified instantly.\n\n🛡️ Every day under protection is a victory. Be proud.` },
    { kw: ['addicted','recover','therapy','support','counseling'],
      r: () => `🌱 **Asking for help takes courage — and you're showing it.**\n\n• Reach out to a local addiction helpline\n• Tell someone you trust today\n• Activate the "Buddy SOS" feature in the app\n\nWe're with you every day. 💚` },
    { kw: ['shield','how','block','dns','work'],
      r: () => `🛡️ **3-layer protection system:**\n\n1. **DNS Filter** — Blocks gambling sites at domain level\n2. **VPN Tunnel** — All traffic through our secure server\n3. **Sabotage Alarm** — Instant alert if app is deleted\n\n99.7% blocking success rate.` },
    { kw: ['sabotage','delete','alarm','bypass'],
      r: () => `⚠️ If you try to delete the app:\n• Your Buddy gets SMS + notification\n• Admin panel generates an alert\n• Alarm triggers within 10 seconds 🔐` },
    { kw: ['subscription','price','payment','cancel','plan'],
      r: () => `💳 Go to iOS Settings → Apple ID → Subscriptions.\n\nPlans: Monthly ₺49.99 | Quarterly ₺129.99 | Annual ₺449.99` },
    { kw: ['thank','great','awesome','perfect'],
      r: () => `😊 You're welcome! The Bahis Koruma family is always here for you. Stay protected. 🛡️` },
  ],
  zh: [
    { kw: ['vpn','连接','断开','不能用','打不开','网络'],
      r: () => `🔒 **我理解您的VPN问题。** 请尝试以下步骤：\n\n1. 完全关闭并重新打开应用。\n2. iOS设置 → VPN → 删除配置文件 → 通过应用重新安装。\n3. 尝试切换Wi-Fi或使用移动数据。\n\n如问题持续，请提交支持工单 — 我们2小时内回复。💪` },
    { kw: ['赌博','赌','博彩','投注','想赌','帮助','戒','戒不掉'],
      r: () => `💙 **我听到您了，我在这里陪伴您。**\n\n想赌博的冲动非常难以抵抗——但这是疾病的声音，不是您本人。\n\n✨ 现在最重要的事：保持保护盾开启，按下"紧急SOS"。您的可信联系人会立刻收到通知。\n\n🛡️ 每一天在保护下都是您的胜利，为自己骄傲。` },
    { kw: ['成瘾','戒断','治疗','心理','咨询'],
      r: () => `🌱 **寻求帮助需要勇气——而您正在展示这种勇气。**\n\n• 拨打当地心理援助热线\n• 今天告诉您信任的人\n• 在应用中激活"Buddy SOS"功能\n\n我们每天都陪伴着您。💚` },
    { kw: ['盾','如何','屏蔽','过滤','工作原理','怎么用'],
      r: () => `🛡️ **三层保护系统：**\n\n1. **DNS过滤器** — 在域名级别屏蔽赌博网站\n2. **VPN隧道** — 所有流量通过我们的安全服务器\n3. **防破坏警报** — 应用被删除时立即发出警报\n\n封锁成功率99.7%。` },
    { kw: ['破坏','删除','警报','绕过'],
      r: () => `⚠️ 如果您尝试删除应用：\n• 您的联系人收到短信+通知\n• 管理面板生成警报\n• 10秒内触发警报 🔐` },
    { kw: ['订阅','价格','付款','取消','套餐'],
      r: () => `💳 前往iOS设置 → Apple ID → 订阅。\n\n套餐：月付₺49.99 | 季付₺129.99 | 年付₺449.99` },
    { kw: ['谢谢','感谢','很好','棒'],
      r: () => `😊 不客气！博彩保护大家庭永远在您身边。保持受保护状态。🛡️` },
  ],
  ar: [
    { kw: ['vpn','اتصال','انقطع','لا يعمل','شبكة','مشكلة'],
      r: () => `🔒 **أفهم مشكلتك مع VPN.** جرّب الخطوات التالية:\n\n1. أغلق التطبيق تماماً وأعد فتحه.\n2. الإعدادات ← VPN ← احذف الملف الشخصي ← أعد التثبيت عبر التطبيق.\n3. جرّب شبكة Wi-Fi مختلفة أو بيانات الجوال.\n\nإذا استمرت المشكلة، افتح طلب دعم — فريقنا يرد خلال ساعتين. 💪` },
    { kw: ['قمار','مراهنة','رهان','أريد','مساعدة','توقف','إدمان'],
      r: () => `💙 **أسمعك وأنا هنا معك.**\n\nالشعور بالرغبة في القمار أمر بالغ الصعوبة — لكنه صوت المرض وليس صوتك.\n\n✨ أقوى شيء يمكنك فعله الآن: أبقِ درعك مفعّلاً واضغط "أرسل SOS". سيتلقى شخصك الموثوق إشعاراً فورياً.\n\n🛡️ كل يوم تقضيه تحت الحماية هو انتصار لك.` },
    { kw: ['إدمان','علاج','نفسي','مساعدة','معالج'],
      r: () => `🌱 **طلب المساعدة يتطلب شجاعة — وأنت تُبديها.**\n\n• اتصل بخط مساعدة الإدمان المحلي\n• أخبر شخصاً تثق به اليوم\n• فعّل ميزة "Buddy SOS" في التطبيق\n\nنحن معك كل يوم. 💚` },
    { kw: ['درع','كيف','حجب','فلتر','يعمل'],
      r: () => `🛡️ **نظام حماية ثلاثي الطبقات:**\n\n1. **فلتر DNS** — يحجب مواقع القمار على مستوى النطاق\n2. **نفق VPN** — كل حركة البيانات عبر خادمنا الآمن\n3. **إنذار مضاد للتخريب** — تنبيه فوري إذا حُذف التطبيق\n\nمعدل الحجب 99.7%.` },
    { kw: ['تخريب','حذف','إنذار','تجاوز'],
      r: () => `⚠️ إذا حاولت حذف التطبيق:\n• يتلقى شخصك رسالة SMS + إشعار\n• تتولّد تنبيهات في لوحة الإدارة\n• ينطلق الإنذار خلال 10 ثوانٍ 🔐` },
    { kw: ['اشتراك','سعر','دفع','إلغاء','خطة'],
      r: () => `💳 اذهب إلى إعدادات iOS ← Apple ID ← الاشتراكات.\n\nالخطط: شهري ₺49.99 | ربع سنوي ₺129.99 | سنوي ₺449.99` },
    { kw: ['شكراً','شكرا','رائع','ممتاز'],
      r: () => `😊 على الرحب والسعة! عائلة Bahis Koruma دائماً بجانبك. ابقَ محمياً. 🛡️` },
  ],
  es: [
    { kw: ['vpn','conexión','conectar','desconect','no funciona','error'],
      r: () => `🔒 **Entiendo tu problema con la VPN.** Prueba estos pasos:\n\n1. Cierra completamente la app y vuelve a abrirla.\n2. Ajustes iOS → VPN → Eliminar perfil → Reinstalar desde la app.\n3. Prueba con una Wi-Fi diferente o datos móviles.\n\nSi el problema persiste, abre un Ticket de Soporte — respondemos en 2 horas. 💪` },
    { kw: ['juego','apostar','apuesta','casino','ganas','ayuda','dejar','adicción'],
      r: () => `💙 **Te escucho y estoy aquí.**\n\nSentir el impulso de apostar es muy difícil — pero es la enfermedad hablando, no tú.\n\n✨ Lo más poderoso que puedes hacer ahora: Mantén tu Escudo activo y presiona "Enviar SOS". Tu contacto de confianza recibirá una notificación inmediata.\n\n🛡️ Cada día bajo protección es una victoria. Siéntete orgulloso.` },
    { kw: ['adicto','recuperar','terapia','apoyo','consejero'],
      r: () => `🌱 **Pedir ayuda requiere valentía — y tú la estás demostrando.**\n\n• Llama a la línea de ayuda local para adicciones\n• Cuéntaselo a alguien de confianza hoy\n• Activa la función "Buddy SOS" en la app\n\nEstamos contigo cada día. 💚` },
    { kw: ['escudo','cómo','bloqueo','dns','funciona'],
      r: () => `🛡️ **Sistema de protección de 3 capas:**\n\n1. **Filtro DNS** — Bloquea sitios de apuestas a nivel de dominio\n2. **Túnel VPN** — Todo el tráfico pasa por nuestro servidor seguro\n3. **Alarma Anti-Sabotaje** — Alerta inmediata si se elimina la app\n\nTasa de bloqueo del 99.7%.` },
    { kw: ['sabotaje','eliminar','alarma','bypass','saltar'],
      r: () => `⚠️ Si intentas eliminar la app:\n• Tu Buddy recibe SMS + notificación\n• Se genera una alerta en el panel admin\n• La alarma se activa en 10 segundos 🔐` },
    { kw: ['suscripción','precio','pago','cancelar','plan'],
      r: () => `💳 Ve a Ajustes iOS → Apple ID → Suscripciones.\n\nPlanes: Mensual ₺49.99 | Trimestral ₺129.99 | Anual ₺449.99` },
    { kw: ['gracias','genial','perfecto','excelente'],
      r: () => `😊 ¡De nada! La familia Bahis Koruma siempre está aquí para ti. Mantente protegido. 🛡️` },
  ],
};

const DEFAULT_REPLIES = {
  tr: `🤖 **Bahis Koruma AI Asistanı**\n\nMesajını aldım! Yardımcı olabileceğim konular:\n\n• 🔒 VPN bağlantı sorunları\n• 🛡️ Kalkan ve engelleme sistemi\n• 💙 Kumar isteği ve bağımlılık desteği\n• ⚠️ Sabotaj koruması\n• 💳 Abonelik yönetimi`,
  en: `🤖 **Bahis Koruma AI Assistant**\n\nGot your message! I can help with:\n\n• 🔒 VPN connection issues\n• 🛡️ Shield & blocking system\n• 💙 Gambling urges & addiction support\n• ⚠️ Sabotage protection\n• 💳 Subscription management`,
  zh: `🤖 **博彩保护AI助手**\n\n收到您的消息！我能帮助您解决：\n\n• 🔒 VPN连接问题\n• 🛡️ 保护盾和屏蔽系统\n• 💙 赌博冲动和成瘾支持\n• ⚠️ 防破坏保护\n• 💳 订阅管理`,
  ar: `🤖 **مساعد Bahis Koruma بالذكاء الاصطناعي**\n\nاستلمت رسالتك! يمكنني المساعدة في:\n\n• 🔒 مشاكل اتصال VPN\n• 🛡️ نظام الدرع والحجب\n• 💙 دعم الرغبة في القمار والإدمان\n• ⚠️ الحماية من التخريب\n• 💳 إدارة الاشتراك`,
  es: `🤖 **Asistente IA Bahis Koruma**\n\n¡Recibí tu mensaje! Puedo ayudarte con:\n\n• 🔒 Problemas de conexión VPN\n• 🛡️ Sistema de Escudo y bloqueo\n• 💙 Impulsos de juego y apoyo para la adicción\n• ⚠️ Protección anti-sabotaje\n• 💳 Gestión de suscripciones`,
};

// ── Language detection ────────────────────────────────────────────────────────
function detectLang(text) {
  if (/[\u0600-\u06FF]/.test(text))  return 'ar';
  if (/[\u4e00-\u9fff]/.test(text))  return 'zh';
  const lower = text.toLowerCase();
  const esWords = ['hola','ayuda','casino','apuesta','juego','gracias','vpn','conexión','error','suscripción','cómo','funciona'];
  if (esWords.some(w => lower.includes(w))) return 'es';
  const enWords = ['help','casino','gambl','bet','vpn','connection','shield','block','thank','subscription','how'];
  if (enWords.some(w => lower.includes(w))) return 'en';
  return 'tr';
}

function getAIReply(message, lang) {
  const rules = LANG_RESPONSES[lang] || LANG_RESPONSES.tr;
  const lower  = (message || '').toLowerCase();
  for (const rule of rules) {
    if (rule.kw.some(k => lower.includes(k))) return rule.r();
  }
  return DEFAULT_REPLIES[lang] || DEFAULT_REPLIES.tr;
}

// ── Routes ────────────────────────────────────────────────────────────────────
router.post('/', (req, res) => {
  const { userId, message, sessionId, lang: reqLang } = req.body || {};
  if (!message || !String(message).trim()) {
    return res.status(400).json({ success: false, error: 'Mesaj boş olamaz / Message cannot be empty' });
  }
  const msgStr   = String(message).trim();
  const lang     = reqLang && LANG_RESPONSES[reqLang] ? reqLang : detectLang(msgStr);
  const reply    = getAIReply(msgStr, lang);
  const now      = new Date();

  const entry = {
    id:        `chat_${Date.now()}`,
    sessionId: sessionId || `session_${(userId || 'anon').slice(0,8)}`,
    userId:    userId || 'anonymous',
    lang,
    userMsg:   msgStr,
    botReply:  reply,
    timestamp: now.toISOString(),
    date:      `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`,
    time:      `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`,
  };
  chatLog.push(entry);
  console.log(`[ai-chat] [${lang.toUpperCase()}] ${entry.userId}: "${msgStr.slice(0,50)}"`);
  res.json({ success: true, reply, lang, entryId: entry.id });
});

router.get('/history', (req, res) => {
  res.json({ success: true, chats: chatLog.slice().reverse() });
});

module.exports = router;
