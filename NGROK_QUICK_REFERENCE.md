# ⚡ جدول سريع ngrok - Reference

**للرجوع السريع أثناء العمل**

---

## 📋 4 Terminals المطلوبة

```
┌─────────────────────────────────────────────────────────────┐
│ Terminal 1: Django Backend                                  │
├─────────────────────────────────────────────────────────────┤
│ cd "Buses_BACK_END-main"                                    │
│ python -m venv .venv                                        │
│ .\.venv\Scripts\Activate.ps1                                │
│ pip install -r requirements.txt                             │
│ python manage.py migrate                                    │
│ python manage.py populate_database                          │
│ python manage.py runserver 127.0.0.1:8000                   │
│                                                             │
│ ✅ النتيجة: Starting development server...                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Terminal 2: ngrok Tunnel                                    │
├─────────────────────────────────────────────────────────────┤
│ ngrok http 8000                                             │
│                                                             │
│ ✅ النتيجة: https://xxxx-xx-xxx-xxx.ngrok.io              │
│ 👈 احفظ هذا الـ URL!                                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Terminal 3: Driver App                                      │
├─────────────────────────────────────────────────────────────┤
│ cd "Driver_APP-main"                                        │
│ flutter pub get                                             │
│ flutter run                                                 │
│                                                             │
│ ✅ النتيجة: تطبيق السائق يفتح                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Terminal 4: User App                                        │
├─────────────────────────────────────────────────────────────┤
│ cd "user_app-main"                                          │
│ flutter pub get                                             │
│ flutter run                                                 │
│                                                             │
│ ✅ النتيجة: تطبيق المستخدم يفتح                           │
└─────────────────────────────────────────────────────────────┘
```

---

## ✏️ 3 ملفات التعديل المطلوبة

### 📄 ملف 1: `BusTrackingSystem/settings.py`

| السطر | البحث | استبدل |
|------|-------|---------|
| ~26 | `ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')` | أضف: `'xxxx-xx-xxx-xxx.ngrok.io'` |
| ~49 | `CSRF_TRUSTED_ORIGINS` | أضف: `'https://xxxx-xx-xxx-xxx.ngrok.io'` |
| ~56 | `CORS_ALLOWED_ORIGINS` | أضف: `'https://xxxx-xx-xxx-xxx.ngrok.io'` |

---

### 📄 ملف 2: `Driver_APP-main/.env`

```diff
- API_BASE_URL=http://127.0.0.1:8000/api
+ API_BASE_URL=https://xxxx-xx-xxx-xxx.ngrok.io/api
```

---

### 📄 ملف 3: `user_app-main/lib/config/app_config.dart`

```diff
- static const String baseUrl = 'http://127.0.0.1:8000';
+ static const String baseUrl = 'https://xxxx-xx-xxx-xxx.ngrok.io';

- static const String websocketUrl = 'ws://127.0.0.1:8000/ws/bus-locations/';
+ static const String websocketUrl = 'wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/';
```

---

## 🧪 الاختبارات السريعة

### ✅ Test 1: API Response
```powershell
curl https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/
```

**النتيجة المتوقعة:**
```json
[{"bus_id": 1, "license_plate": "0101465", ...}]
```

---

### ✅ Test 2: Driver App
```
1. التطبيق يفتح ✓
2. اختر الحافلة 0101465 ✓
3. اضغط Start Tracking ✓
4. "✅ تم الإرسال بنجاح" ✓
```

---

### ✅ Test 3: User App
```
1. التطبيق يفتح ✓
2. خريطة تظهر ✓
3. الحافلة موجودة ✓
4. الموقع يتحدث تلقائياً ✓
```

---

### ✅ Test 4: من أي جهاز
```
https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/
→ يجب يشتغل من أي جهاز على الإنترنت
```

---

## ⏱️ Timeline الكامل

```
0:00 - 0:05   → تثبيت ngrok
0:05 - 0:10   → تشغيل Django
0:10 - 0:11   → تشغيل ngrok (احصل على URL)
0:11 - 0:12   → نسخ الـ URL
0:12 - 0:15   → تحديث settings.py
0:15 - 0:17   → تحديث .env + app_config.dart
0:17 - 0:22   → تشغيل التطبيقات (Driver + User)
0:22 - 0:40   → الاختبار الشامل
────────────────
0:40 TOTAL    → نظام كامل على الإنترنت! 🎉
```

---

## 🔍 Troubleshooting السريع

| المشكلة | السبب | الحل |
|--------|------|------|
| `Connection refused` | Django مو شغال | شغّل Terminal 1 |
| `Invalid hostname` | الـ URL خطأ | انسخ الـ URL من ngrok |
| `CORS error` | CORS ناقص | أضف ngrok URL في settings.py |
| `WebSocket fail` | استخدام ws بدل wss | غيّر ws إلى wss |
| `404 Not Found` | الـ API path خطأ | تأكد من `/api/` في الـ URL |

---

## 📱 URLs الرئيسية

| الاستخدام | الـ URL |
|----------|---------|
| **REST API** | `https://xxxx-xx-xxx-xxx.ngrok.io/api/` |
| **Buses** | `https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/` |
| **Bus Lines** | `https://xxxx-xx-xxx-xxx.ngrok.io/api/bus-lines/` |
| **WebSocket** | `wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/` |
| **Admin Panel** | `https://xxxx-xx-xxx-xxx.ngrok.io/admin/` |

---

## 🔐 البيانات الثابتة

```
👤 Username: aaa
🔑 Token: d1afc8c6685f541724963a55cd0ebca599dac16f
🚌 Bus License Plate: 0101465
🚏 Bus Line: زراعة مرفأ
📍 Stops: زراعة, يمن
```

---

## 📊 الإحصائيات

```
Servers:              1 (Django)
Tunnels:              1 (ngrok)
Applications:         2 (Driver + User)
Terminals Needed:     4
Files to Edit:        3
Configuration Items:  7
Time Required:        40 minutes
Final Status:         🟢 Ready for Production
```

---

## 🎯 Checklist النهائي

- [ ] ngrok مثبت
- [ ] Django شغّال في Terminal 1
- [ ] ngrok tunnel نشط في Terminal 2
- [ ] عندك الـ ngrok URL
- [ ] حدّثت settings.py بـ ALLOWED_HOSTS
- [ ] حدّثت settings.py بـ CSRF_TRUSTED_ORIGINS
- [ ] حدّثت settings.py بـ CORS_ALLOWED_ORIGINS
- [ ] حدّثت .env بـ API_BASE_URL
- [ ] حدّثت app_config.dart بـ baseUrl
- [ ] حدّثت app_config.dart بـ websocketUrl (wss://)
- [ ] Driver App شغّال في Terminal 3
- [ ] User App شغّال في Terminal 4
- [ ] اختبرت API من المتصفح
- [ ] اختبرت من الهاتف الحقيقي
- [ ] كل شيء يعمل! ✅

---

## 💾 الملفات المراجعية

```
اقرأ للشرح:      NGROK_SETUP_GUIDE.md
اقرأ للأمثلة:    NGROK_CONFIG_EXAMPLES.md
اقرأ للأوامر:    NGROK_QUICK_START.md
اقرأ للملخص:     NGROK_FINAL_SUMMARY.md
```

---

## 🚀 ابدأ الآن!

```
1. اطبع هذا الملف
2. افتح 4 Terminals
3. انسخ الأوامر من أعلى
4. حدّث الملفات الثلاثة
5. شغّل التطبيقات
6. اختبر
7. Done! 🎉
```

---

**آخر تحديث**: 28 أكتوبر 2025  
**القالب**: جاهز للطباعة والاستخدام المباشر
