import 'package:latlong2/latlong.dart';

enum BusStatus { IN_SERVICE, DELAYED, NOT_IN_SERVICE, UNKNOWN }

class Bus {
  final String id;
  final String licensePlate;
  final LatLng position;
  final String lineId;
  final BusStatus status;

  Bus({
    required this.id,
    required this.licensePlate,
    required this.position,
    required this.lineId,
    this.status = BusStatus.UNKNOWN,
  });

  // دالة لنسخ الكائن مع تغيير بعض الخصائص
  Bus copyWith({
    String? id,
    String? licensePlate,
    LatLng? position,
    String? lineId,
    BusStatus? status,
  }) {
    return Bus(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      position: position ?? this.position,
      lineId: lineId ?? this.lineId,
      status: status ?? this.status,
    );
  }

  // دالة لتحويل JSON إلى كائن Bus
  // هذا يفترض أن الخادم سيرسل الحالة كنص (string)
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      licensePlate: json['licensePlate'],
      position: LatLng(json['position']['lat'], json['position']['lng']),
      lineId: json['lineId'],
      status: _statusFromString(json['status']),
    );
  }

  // دالة مساعدة لتحويل النص إلى BusStatus
  static BusStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'IN_SERVICE':
        return BusStatus.IN_SERVICE;
      case 'DELAYED':
        return BusStatus.DELAYED;
      case 'NOT_IN_SERVICE':
        return BusStatus.NOT_IN_SERVICE;
      default:
        return BusStatus.UNKNOWN;
    }
  }
}
