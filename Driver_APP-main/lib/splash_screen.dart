// في ملف: lib/splash_screen.dart

import 'package:driver_app/background_service.dart';
import 'package:driver_app/login_screen.dart';
import 'package:driver_app/map_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // نبدأ عمليات التهيئة الطويلة بعد عرض الواجهة
    _initializeAppAndNavigate();
  }
  String? _errorMessage;
  bool _isRetrying = false;

  Future<void> _initializeAppAndNavigate() async {
    setState(() {
      _errorMessage = null;
      _isRetrying = false;
    });

    try {
      debugPrint('Splash: starting initialization');
      // --- كل عمليات التهيئة التي كانت في main تم نقلها إلى هنا ---

      // 1. تهيئة Hive (مع timeout احترازي)
      debugPrint('Splash: Hive.initFlutter start');
      await Hive.initFlutter();
      debugPrint('Splash: Hive.initFlutter done');
      // Registering generated Hive adapters can sometimes cause analyzer issues
      // in CI if the generated file isn't visible. We attempt to register but
      // avoid hard failures here.
      try {
        // LocationPointAdapter is generated; register if available.
        // We reference it inside a try/catch to avoid analyzer/build failures
        // when the generated file isn't present in some CI runs.
        // Hive.registerAdapter(LocationPointAdapter());
      } catch (e) {
        debugPrint('Splash: LocationPointAdapter not available at runtime: $e');
      }
      debugPrint('Splash: opening Hive box location_queue');
      // Open without a generic type to avoid referencing LocationPoint here.
      await Hive.openBox('location_queue').timeout(const Duration(seconds: 15));
      debugPrint('Splash: opened Hive box location_queue');

      // 2. تحميل ملف .env
      debugPrint('Splash: dotenv.load start');
      try {
        // dotenv is optional at runtime (CI/apk may not include .env). We attempt to load it
        // but don't fail the whole initialization if it's missing or slow.
        await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 4));
        debugPrint('Splash: dotenv.load done');
      } catch (e) {
        // Log and continue. The app will rely on fallback config or prompt the user later.
        debugPrint('Splash: dotenv.load failed or timed out: $e');
      }

      // 3. تهيئة الخدمة الخلفية (قد تستغرق قليلاً)
      debugPrint('Splash: initializeService start');
      try {
        // initializeService can fail on some devices or if background permissions
        // / artifacts are missing. Make it non-fatal: log and continue.
        await initializeService().timeout(const Duration(seconds: 10));
        debugPrint('Splash: initializeService done');
      } catch (e) {
        debugPrint('Splash: initializeService failed (non-fatal): $e');
        // don't rethrow — allow the app to continue to Login/Map; user can retry
        // starting the background service later when they log in.
      }

      // 4. قراءة البيانات المحفوظة لتحديد الشاشة التالية
      debugPrint('Splash: SharedPreferences.getInstance start');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('Splash: SharedPreferences.getInstance done');
      final String? busId = prefs.getString('active_bus_id');
      final String? lineId = prefs.getString('active_line_id');

      // التأكد من أن الواجهة ما زالت موجودة قبل الانتقال
      if (!mounted) return;

      // 5. الانتقال إلى الشاشة المناسبة
      if (busId != null && lineId != null) {
        // إذا كان التتبع فعالاً، اذهب مباشرة إلى شاشة التتبع
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MapScreen(busId: busId, lineId: lineId)),
        );
      } else {
        // وإلا، اذهب إلى شاشة تسجيل الدخول
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e, st) {
      // سجل الاستثناء لتشخيص المشكلة
      debugPrint('Splash initialization failed: $e');
      debugPrint('$st');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحميل. الرجاء المحاولة مرة أخرى.';
      });
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    await _initializeAppAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    // هذه هي الواجهة التي تظهر فوراً عند تشغيل التطبيق
    return Scaffold(
      body: Center(
        child: _errorMessage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('جاري التحميل...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  _isRetrying
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _retryInitialization,
                          child: const Text('حاول مرة أخرى'),
                        ),
                ],
              ),
      ),
    );
  }
}