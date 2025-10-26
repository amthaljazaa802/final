@echo off
echo ========================================
echo   🚀 تشغيل سيرفر تتبع الحافلات
echo ========================================
echo.
echo 📡 عنوان IP: 192.168.0.166
echo 🌐 السيرفر سيكون متاح على: http://192.168.0.166:8000
echo 🔌 WebSocket: ws://192.168.0.166:8000/ws/bus-locations/
echo.
echo ⚠️  تأكد من:
echo    - جميع الأجهزة على نفس WiFi
echo    - Firewall لا يمنع port 8000
echo.
echo ========================================
echo.

py manage.py runserver 0.0.0.0:8000
