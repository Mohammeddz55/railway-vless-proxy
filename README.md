# railway-vless-proxy
# Railway VLESS Proxy

Proxy VLESS over WebSocket على Railway، متوافق مع DarkTunnel.

## البنية

```

Railway Edge (HTTPS + TLS)
↓
Caddy :8080  ← يستقبل كل الطلبات
↓ /ws → Xray :8081

```

## النشر خطوة بخطوة

### 1. أنشئ مستودعاً جديداً على GitHub باسم `railway-vless-proxy`

### 2. ارفع هذه الملفات الأربعة إلى الجذر:
- `Dockerfile`
- `config.json`
- `start.sh`
- `README.md`

### 3. في Railway: New Project → Deploy from GitHub repo → اختر المستودع

### 4. أنشئ نطاقاً عاماً:
- Settings → Networking → **Generate Domain**
- احفظ النطاق (مثال: `xxx.up.railway.app`)

### 5. اختبر الصحة:
```

https://YOUR_DOMAIN.up.railway.app/health

```
يجب أن ترى **OK**

### 6. رابط VLESS لـ DarkTunnel:

```

vless://944b54e0-e81b-4fa9-bc26-65b81d3ed393@YOUR_DOMAIN.up.railway.app:443?encryption=none&security=tls&sni=YOUR_DOMAIN.up.railway.app&type=ws&host=YOUR_DOMAIN.up.railway.app&path=%2Fws#RailwayVLESS

```

استبدل `YOUR_DOMAIN` بنطاقك الفعلي.

### 7. استيراد في DarkTunnel:
- Config → Import → From Clipboard
- الصق الرابط
- اضغط Connect

## الإعدادات

| الإعداد | القيمة |
|---|---|
| UUID | `944b54e0-e81b-4fa9-bc26-65b81d3ed393` |
| Port | 443 (عام) |
| Path | `/ws` |
| Transport | WebSocket |
| TLS | نعم (يديرها Railway) |
| SNI | نطاق Railway |

## استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| `/health` لا يرد 200 | افحص Deploy Logs |
| الاتصال يفشل | تأكد من UUID و Path في DarkTunnel |
| 404 من Railway Edge | تأكد أن Networking مربوط بـ 8080 |
```

---

📋 خطوات التطبيق

1. احذف المستودع القديم من GitHub (أو لا تستخدمه).
2. أنشئ مستودعاً جديداً: railway-vless-proxy
3. ارفع 4 ملفات (Dockerfile، config.json، start.sh، README.md)
4. في Railway:
   · احذف المشروع القديم (Settings → Danger → Delete Project) أو
   · أنشئ مشروعاً جديداً مربوطاً بالمستودع الجديد
5. انتظر النشر (60-90 ثانية)
6. أنشئ نطاقاً عاماً من Settings → Networking
7. اختبر: https://YOUR_DOMAIN.up.railway.app/health → يجب أن يرد OK
8. ابنِ رابط VLESS واستورده في DarkTunnel

---

🔗 صيغة VLESS النهائية

بعد الحصول على النطاق (مثلاً railway-vless-proxy-production.up.railway.app):

```
vless://944b54e0-e81b-4fa9-bc26-65b81d3ed393@railway-vless-proxy-production.up.railway.app:443?encryption=none&security=tls&sni=railway-vless-proxy-production.up.railway.app&type=ws&host=railway-vless-proxy-production.up.railway.app&path=%2Fws#RailwayVLESS
```

التغييرات المهمة:

· path=%2Fws (بدل %2F) ← المسار الجديد /ws
· sni = نطاق Railway (إلزامي)
· host = نطاق Railway

---

🎯 ملخص الفروقات عن المحاولات السابقة

العنصر السابق الجديد
Reverse proxy لا يوجد Caddy ✅
/health 400 200 OK ✅
مسار WebSocket / /ws (أوضح)
Xray listening 0.0.0.0:8080 127.0.0.1:8081 (معزول)
Public port 8080 8080 (Caddy)
المصادقة UUID UUID

---

ابدأ من الصفر وطبق الخطوات بالترتيب، وأخبرني بنتيجة /health أولاً 🚀
