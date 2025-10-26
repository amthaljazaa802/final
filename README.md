# 🚌 نظام تتبع الحافلات - دليل كامل

## 📁 هيكل المشروع

```
final masar/
├── Buses_BACK_END-main/        # السيرفر (Django)
├── Driver_APP-main/            # تطبيق السائق (Flutter) ⭐
├── user_app-main/              # تطبيق المستخدم (Flutter)
├── QUICK_START.md             # دليل البدء السريع ⭐⭐⭐
├── DEPLOYMENT_GUIDE.md        # دليل النشر الكامل
└── MAIN_README.md             # هذا الملف
```

---

## ⚡ البدء السريع (3 خطوات)

### 1️⃣ تشغيل السيرفر
```powershell
cd "Buses_BACK_END-main"
START_SERVER_NETWORK.bat
```

### 2️⃣ بناء تطبيق السائق
```powershell
cd "Driver_APP-main"
flutter build apk --release
```

### 3️⃣ تثبيت على الهاتف
- الملف في: `Driver_APP-main\build\app\outputs\flutter-apk\app-release.apk`
- انسخه للهاتف وثبّته

✅ **جاهز!** افتح التطبيق واختر الحافلة "0101465" وابدأ التتبع

---

## 🎯 ما تم إعداده لك اليوم

### ✅ قاعدة البيانات (موجودة مسبقاً)
- **مستخدم:** aaa
- **Token:** `d1afc8c6685f541724963a55cd0ebca599dac16f`
- **حافلة:** 0101465 (خط: زراعة مرفأ)
- **محطات:** 2 (زراعة، يمن)

### ✅ إعدادات الشبكة (تم تحديثها)
- **IP الحالي:** 192.168.0.166
- **السيرفر:** http://192.168.0.166:8000
- **WebSocket:** ws://192.168.0.166:8000/ws/bus-locations/

### ✅ التطبيقات (تم تحديثها)
- **Driver_APP-main/.env:** محدّث بـ IP الجديد + Token الصحيح
- **user_app-main/lib/config/app_config.dart:** 
  - محدّث بـ IP الجديد
  - `useMockData = false` (استخدام بيانات حقيقية)
- **Django settings.py:** `ALLOWED_HOSTS = ['*']`

---

## 🚀 ابدأ الآن!

افتح [QUICK_START.md](QUICK_START.md) واتبع التعليمات! 🎉

---

**Happy Tracking! 🚌✨**
