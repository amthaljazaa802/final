# 🚀 دليل التشغيل الكامل - نظام تتبع الحافلات

## ✅ البيانات الموجودة

لديك في قاعدة البيانات:
- **👤 مستخدم:** aaa
- **🔑 Token:** d1afc8c6685f541724963a55cd0ebca599dac16f
- **🚌 خط:** زراعة مرفأ
- **🚏 محطتين:** زراعة، يمن
- **🚍 حافلة واحدة:** 0101465

---

## 🌐 الخطوة 1: تشغيل السيرفر على الشبكة

### A) معرفة عنوان IP الخاص بجهازك

```powershell
ipconfig | findstr IPv4
```

سيظهر لك شيء مثل:
```
IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

### B) تشغيل السيرفر

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\Buses_BACK_END-main"
py manage.py runserver 0.0.0.0:8000
```

⚠️ **ملاحظة:** `0.0.0.0:8000` يعني السيرفر سيكون متاح لجميع الأجهزة على الشبكة

### C) تحديث ALLOWED_HOSTS في settings.py

افتح `BusTrackingSystem/settings.py` وتأكد من:
```python
ALLOWED_HOSTS = ['*']  # أو ضع IP محدد مثل ['192.168.1.100', 'localhost']
```

---

## 📱 الخطوة 2: تجهيز تطبيق السائق (Driver_APP-main)

### A) تحديث ملف .env

أنشئ ملف `.env` في مجلد `Driver_APP-main`:

```env
# ⚠️ غيّر 192.168.1.100 إلى IP جهازك الحقيقي
API_BASE_URL=http://192.168.1.100:8000/api
AUTH_TOKEN=d1afc8c6685f541724963a55cd0ebca599dac16f
```

### B) تثبيت الحزم

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\Driver_APP-main"
flutter pub get
```

### C) تشغيل التطبيق

```powershell
# للتشغيل على Android
flutter run

# أو لبناء APK للتثبيت على الهاتف
flutter build apk --release
```

الملف سيكون في: `Driver_APP-main/build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 الخطوة 3: تجهيز تطبيق المستخدم (user_app-main)

### تحديث AppConfig

افتح `user_app-main/lib/config/app_config.dart`:

```dart
class AppConfig {
  // ⚠️ غيّر IP_ADDRESS إلى عنوان IP الحقيقي لجهازك
  static const String baseUrl = 'http://192.168.1.100:8000';
  static const String websocketUrl = 'ws://192.168.1.100:8000/ws/bus-locations/';
  static const String authToken = 'd1afc8c6685f541724963a55cd0ebca599dac16f';
  static const bool useMockData = false; // ⚠️ تأكد أنها false
}
```

---

## 🧪 الخطوة 4: الاختبار

### 1. اختبار API من الهاتف/الجهاز الآخر

من متصفح الهاتف، افتح:
```
http://192.168.1.100:8000/api/buses/
```

يجب أن ترى:
```json
[
  {
    "bus_id": 1,
    "license_plate": "0101465",
    "bus_line": {...}
  }
]
```

### 2. تشغيل تطبيق السائق

1. افتح تطبيق السائق على الهاتف
2. سجل دخول
3. اختر الحافلة "0101465"
4. اضغط "بدء التتبع"
5. يجب أن ترى "تم الإرسال بنجاح ✅"

### 3. مراقبة WebSocket

في الـ Terminal:
```powershell
cd "c:\Users\Windows.11\Desktop\final masar\Buses_BACK_END-main"
py listen_websocket.py
```

يجب أن ترى رسائل تحديث الموقع تصل مباشرة!

### 4. تشغيل تطبيق المستخدم

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\user_app-main"
flutter run
```

يجب أن ترى الحافلة تتحرك على الخريطة في الوقت الفعلي! 🎉

---

## 🔧 حل المشاكل الشائعة

### المشكلة: التطبيق لا يتصل بالسيرفر

✅ **الحل:**
1. تأكد أن الجهازين على نفس الشبكة (WiFi)
2. تأكد أن Firewall لا يمنع port 8000
3. جرب ping من الهاتف:
   ```
   ping 192.168.1.100
   ```

### المشكلة: WebSocket لا يعمل

✅ **الحل:**
1. تأكد من CHANNEL_LAYERS في settings.py
2. تأكد من تثبيت channels: `py -m pip install channels`
3. تأكد من ASGI في asgi.py

### المشكلة: "SSL Certificate Error"

✅ **الحل:** تطبيق السائق عندك فيه `MyHttpOverrides` يتعامل مع هذا

---

## 📝 ملاحظات مهمة

1. **🔒 الأمان:** 
   - `ALLOWED_HOSTS = ['*']` للتطوير فقط
   - في الإنتاج، استخدم HTTPS ودومين حقيقي

2. **📡 الشبكة:**
   - تأكد أن جميع الأجهزة على نفس WiFi
   - بعض الشبكات تمنع الاتصال بين الأجهزة (AP Isolation)

3. **🔋 البطارية:**
   - تطبيق السائق يستخدم GPS وشبكة باستمرار
   - متوقع استهلاك بطارية عالي

4. **📍 الدقة:**
   - التطبيق يرسل الموقع كل 5 ثوانٍ
   - يمكن تغيير المدة في `background_service.dart`

---

## 🎯 الخطوات التالية

1. ✅ احصل على IP جهازك
2. ✅ حدّث `.env` في Driver_APP
3. ✅ حدّث `app_config.dart` في user_app
4. ✅ شغّل السيرفر: `py manage.py runserver 0.0.0.0:8000`
5. ✅ ابني APK: `flutter build apk --release`
6. ✅ نزّل APK على الهاتف
7. ✅ جرّب!

---

## 🆘 الدعم

إذا واجهت أي مشكلة:
1. شوف الـ logs في Terminal
2. افحص `py check_database.py`
3. جرب الـ API من المتصفح أولاً
