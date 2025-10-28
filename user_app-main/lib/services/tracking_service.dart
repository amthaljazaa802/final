import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/bus.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../config/app_config.dart';
import 'mock_data_provider.dart';

class TrackingService {
  // ميزاتك الحالية تبقى كما هي
  final bool _useMockData = AppConfig.useMockData;

  // --- WebSocket Connection ---
  WebSocketChannel? _channel;
  StreamSubscription? _webSocketSubscription;
  bool _isWebSocketConnected = false;

  // --- 1. إضافة ذاكرة تخزين مؤقت (Cache) لكل نوع من البيانات ---
  final List<Bus> _buses = [];
  final List<BusStop> _busStops = [];
  final List<BusLine> _busLines = [];

  // Simple content signatures to avoid emitting identical data repeatedly
  int _busesSig = 0;
  int _busStopsSig = 0;
  int _busLinesSig = 0;

  // Movement-based throttling for bus updates
  final Map<String, LatLng> _lastBusPositions = <String, LatLng>{};
  DateTime _lastBusEmit = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _busEmitCooldown = Duration(milliseconds: 900);
  static const Duration _busEmitMaxInterval = Duration(seconds: 5);
  static const double _busMovementThresholdMeters =
      30.0; // ~1–2 frames/sec + significant move

  // --- 2. إضافة Getters للوصول الفوري للبيانات المخزنة ---
  //    هذا يسمح لأي شاشة بسؤال الخدمة عن آخر بيانات لديها.
  List<Bus> get buses => _buses;
  List<BusStop> get busStops => _busStops;
  List<BusLine> get busLines => _busLines;

  // Controllers and Streams (تبقى كما هي للتحديثات الحية)
  final StreamController<List<Bus>> _busController =
      StreamController.broadcast();
  final StreamController<List<BusStop>> _busStopsController =
      StreamController.broadcast();
  final StreamController<List<BusLine>> _busLinesController =
      StreamController.broadcast();

  Stream<List<Bus>> get busStream => _busController.stream;
  Stream<List<BusStop>> get busStopsStream => _busStopsController.stream;
  Stream<List<BusLine>> get busLinesStream => _busLinesController.stream;

  final String _apiUrl = AppConfig.baseUrl;

  // --- WebSocket Configuration ---
  // لا نحتاج متغير منفصل لـ WebSocket URL لأننا نستخدمه مباشرة من AppConfig

  /// الاتصال بـ Secure WebSocket (wss://) للحصول على تحديثات مباشرة لمواقع الحافلات
  ///
  /// الاتصال: User app ↔ Server عبر WebSocket الآمن (wss://)
  /// المصادقة: Token-based authentication
  ///
  /// عند الاتصال بـ wss://:
  /// 1. تأكد من وجود شهادة SSL صحيحة على الخادم
  /// 2. في Debug mode: قد يتطلب تخطي التحقق من الشهادة (للـ self-signed certs)
  /// 3. في Release: يجب استخدام شهادة SSL صحيحة من جهة موثوقة
  void connectToWebSocket() {
    if (_isWebSocketConnected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }

    try {
      final wsUrl = AppConfig.websocketUrl;
      debugPrint('[WebSocket] Connecting to $wsUrl');

      // بناء اتصال WebSocket آمن (wss://)
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _isWebSocketConnected = true;

      _webSocketSubscription = _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _isWebSocketConnected = false;
          _reconnectWebSocket();
        },
        onDone: () {
          debugPrint('[WebSocket] Connection closed');
          _isWebSocketConnected = false;
          _reconnectWebSocket();
        },
      );

      debugPrint('[WebSocket] Connected successfully to wss://');
    } catch (e) {
      debugPrint('[WebSocket] Connection failed: $e');
      _isWebSocketConnected = false;
      _reconnectWebSocket();
    }
  }

  /// معالجة الرسائل الواردة من WebSocket
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      debugPrint('[WebSocket] Received: $data');

      // تحديث موقع الحافلة في القائمة
      final busId = data['bus_id']?.toString();
      final latitude = data['latitude'];
      final longitude = data['longitude'];

      if (busId != null && latitude != null && longitude != null) {
        final busIndex = _buses.indexWhere((bus) => bus.id == busId);
        if (busIndex != -1) {
          // تحديث موقع الحافلة الموجودة
          _buses[busIndex] = _buses[busIndex].copyWith(
            position: LatLng(latitude, longitude),
          );
          _emitBusesIfChanged();
          debugPrint('[WebSocket] Updated bus $busId position');
        } else {
          debugPrint('[WebSocket] Bus $busId not found in cache');
        }
      }
    } catch (e) {
      debugPrint('[WebSocket] Error parsing message: $e');
    }
  }

  /// إعادة الاتصال بـ WebSocket بعد فترة انتظار
  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isWebSocketConnected) {
        debugPrint('[WebSocket] Attempting to reconnect...');
        connectToWebSocket();
      }
    });
  }

  /// قطع الاتصال بـ WebSocket
  void disconnectWebSocket() {
    debugPrint('[WebSocket] Disconnecting...');
    _webSocketSubscription?.cancel();
    _channel?.sink.close();
    _isWebSocketConnected = false;
  }

  // الدالة الرئيسية الذكية (تبقى كما هي)
  Future<void> fetchInitialData() async {
    if (_useMockData) {
      debugPrint('[log] Using Mock Data mode. Loading all fake data...');
      await _loadMockData();
    } else {
      debugPrint(
        '[log] Using Real Data mode. Fetching all data from server...',
      );
      await _loadRealDataFromServer();
      // الاتصال بـ WebSocket للحصول على تحديثات مباشرة
      connectToWebSocket();
    }
  }

  // دالة البيانات الوهمية (تم تحديثها لتعبئة الذاكرة)
  Future<void> _loadMockData() async {
    await Future.delayed(const Duration(seconds: 1));

    // --- 3. تخزين البيانات في الذاكرة المؤقتة (Cache) ---
    _busStops.clear(); // مسح البيانات القديمة قبل إضافة الجديدة
    _busStops.addAll(MockDataProvider.getMockStops());

    _buses.clear();
    _buses.addAll(MockDataProvider.getMockBuses());

    _busLines.clear();
    _busLines.addAll(MockDataProvider.getMockBusLines());

    // --- 4. بث البيانات عبر الـ Streams كما كان ---
    _emitBusStopsIfChanged();
    _emitBusesIfChanged();
    _emitBusLinesIfChanged();

    debugPrint('[log] Mock data cached and broadcasted successfully.');
  }

  // دالة البيانات الحقيقية (تم تحديثها لتعبئة الذاكرة)
  Future<void> _loadRealDataFromServer() async {
    try {
      // إعداد Headers مع Token للمصادقة
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${AppConfig.authToken}',
      };

      final stopsResponse = await http.get(
        Uri.parse('$_apiUrl/api/bus-stops/'),
        headers: headers,
      );
      if (stopsResponse.statusCode == 200) {
        final List<dynamic> stopsJson = json.decode(stopsResponse.body);
        final List<BusStop> stops = stopsJson
            .map((json) => BusStop.fromJson(json))
            .toList();
        _busStops.clear();
        _busStops.addAll(stops);
        _emitBusStopsIfChanged();
      } else {
        throw Exception(
          'Failed to load bus stops: ${stopsResponse.statusCode}',
        );
      }

      final busesResponse = await http.get(
        Uri.parse('$_apiUrl/api/buses/'),
        headers: headers,
      );
      if (busesResponse.statusCode == 200) {
        final List<dynamic> busesJson = json.decode(busesResponse.body);
        final List<Bus> buses = busesJson
            .map((json) => Bus.fromJson(json))
            .toList();
        _buses.clear();
        _buses.addAll(buses);
        _emitBusesIfChanged();
      } else {
        throw Exception('Failed to load buses: ${busesResponse.statusCode}');
      }

      final linesResponse = await http.get(
        Uri.parse('$_apiUrl/api/bus-lines/'),
        headers: headers,
      );
      if (linesResponse.statusCode == 200) {
        final List<dynamic> linesJson = json.decode(linesResponse.body);
        final List<BusLine> lines = linesJson
            .map((json) => BusLine.fromJson(json))
            .toList();
        _busLines.clear();
        _busLines.addAll(lines);
        _emitBusLinesIfChanged();
      } else {
        throw Exception(
          'Failed to load bus lines: ${linesResponse.statusCode}',
        );
      }

      debugPrint(
        '[API] Successfully loaded data from server with authentication',
      );
    } catch (e) {
      debugPrint('[API] Error loading data: $e');
      _busStopsController.addError('Failed to fetch stops: $e');
      _busController.addError('Failed to fetch buses: $e');
      _busLinesController.addError('Failed to fetch lines: $e');
    }
  }

  // دالة dispose (تبقى كما هي)
  void dispose() {
    disconnectWebSocket();
    _busController.close();
    _busStopsController.close();
    _busLinesController.close();
    debugPrint('[log] TrackingService disposed and all streams closed.');
  }

  // --- Helpers: emit only when content changed (cheap signatures) ---
  void _emitBusesIfChanged() {
    // Higher precision to detect smaller movements (~11m per 1e-4 deg latitude)
    final sig = _hashList<Bus>(
      _buses,
      (b) => _hashValues([
        b.id.hashCode,
        (b.position.latitude * 10000).round(),
        (b.position.longitude * 10000).round(),
        b.lineId.hashCode,
        b.status.index,
      ]),
    );

    final now = DateTime.now();
    final cooldownOk = now.difference(_lastBusEmit) >= _busEmitCooldown;
    final maxMove = _computeMaxFleetMovementMeters(_buses);
    final movedSignificantly = maxMove >= _busMovementThresholdMeters;
    final maxIntervalElapsed =
        now.difference(_lastBusEmit) >= _busEmitMaxInterval;

    // Only emit if content changed and either we moved enough, cooldown passed, or a safety interval elapsed
    if (sig != _busesSig &&
        cooldownOk &&
        (movedSignificantly || maxIntervalElapsed)) {
      _busesSig = sig;
      _lastBusEmit = now;
      _updateLastBusPositions(_buses);
      _busController.add(List<Bus>.unmodifiable(_buses));
    }
  }

  void _emitBusStopsIfChanged() {
    final sig = _hashList<BusStop>(
      _busStops,
      (s) => _hashValues([
        s.id.hashCode,
        (s.latitude * 10000).round(),
        (s.longitude * 10000).round(),
        s.name.hashCode,
      ]),
    );
    if (sig != _busStopsSig) {
      _busStopsSig = sig;
      _busStopsController.add(List<BusStop>.unmodifiable(_busStops));
    }
  }

  void _emitBusLinesIfChanged() {
    final sig = _hashList<BusLine>(
      _busLines,
      (l) =>
          _hashValues([l.id.hashCode, l.name.hashCode, l.description.hashCode]),
    );
    if (sig != _busLinesSig) {
      _busLinesSig = sig;
      _busLinesController.add(List<BusLine>.unmodifiable(_busLines));
    }
  }

  int _hashList<T>(List<T> items, int Function(T) itemHash) {
    var hash = items.length;
    for (final item in items) {
      hash = _combine(hash, itemHash(item));
    }
    return _finish(hash);
  }

  int _hashValues(List<Object?> values) {
    var hash = 0;
    for (final v in values) {
      hash = _combine(hash, v?.hashCode ?? 0);
    }
    return _finish(hash);
  }

  int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  int _finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  // --- Movement helpers ---
  double _computeMaxFleetMovementMeters(List<Bus> buses) {
    double maxMeters = 0.0;
    for (final b in buses) {
      final prev = _lastBusPositions[b.id];
      if (prev == null) {
        // First time seeing this bus; treat as moved to allow initial emission
        maxMeters = _busMovementThresholdMeters;
        continue;
      }
      final meters = _distanceMetersApprox(prev, b.position);
      if (meters > maxMeters) maxMeters = meters;
    }
    return maxMeters;
  }

  void _updateLastBusPositions(List<Bus> buses) {
    for (final b in buses) {
      _lastBusPositions[b.id] = b.position;
    }
  }

  // Haversine approximation to avoid extra deps in service layer
  double _distanceMetersApprox(LatLng a, LatLng b) {
    const double R = 6371000.0; // meters
    final double dLat = _deg2rad(b.latitude - a.latitude);
    final double dLon = _deg2rad(b.longitude - a.longitude);
    final double lat1 = _deg2rad(a.latitude);
    final double lat2 = _deg2rad(b.latitude);
    final double s =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.sin(dLon / 2) * math.sin(dLon / 2)) *
            math.cos(lat1) *
            math.cos(lat2);
    final double c = 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);
}
