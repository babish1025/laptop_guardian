class DeviceModel {
  final String deviceId;
  final String deviceName;
  final String status;        // ONLINE | OFFLINE | SHUTDOWN
  final DateTime? lastSeen;
  final String? os;
  final String? cpu;
  final String? ram;
  final String? gpu;
  final String? manufacturer;
  final String? model;
  final String? username;
  final String? ipAddress;
  final int? batteryLevel;
  final bool batteryCharging;

  // Latest location (joined from locations table)
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? locSource;
  final bool? isApproximate;
  final DateTime? locationUpdatedAt;

  const DeviceModel({
    required this.deviceId,
    required this.deviceName,
    required this.status,
    this.lastSeen,
    this.os,
    this.cpu,
    this.ram,
    this.gpu,
    this.manufacturer,
    this.model,
    this.username,
    this.ipAddress,
    this.batteryLevel,
    this.batteryCharging = false,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.locSource,
    this.isApproximate,
    this.locationUpdatedAt,
  });

  bool get isOnline => status == 'ONLINE';

  String get locationLabel {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'Location unavailable';
  }

  factory DeviceModel.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v as String).toLocal(); } catch (_) { return null; }
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return DeviceModel(
      deviceId:      j['device_id']?.toString() ?? '',
      deviceName:    j['device_name']?.toString() ?? 'Unknown',
      status:        j['status']?.toString() ?? 'OFFLINE',
      lastSeen:      parseDate(j['last_seen']),
      os:            j['os']?.toString(),
      cpu:           j['cpu']?.toString(),
      ram:           j['ram']?.toString(),
      gpu:           j['gpu']?.toString(),
      manufacturer:  j['manufacturer']?.toString(),
      model:         j['model']?.toString(),
      username:      j['username']?.toString(),
      ipAddress:     j['ip_address']?.toString(),
      batteryLevel:  parseInt(j['battery_level']),
      batteryCharging: j['battery_charging'] == true || j['battery_charging'] == 1 || j['battery_charging'] == 'true',
      latitude:      parseDouble(j['latitude']),
      longitude:     parseDouble(j['longitude']),
      city:          j['city']?.toString(),
      state:         j['state']?.toString(),
      country:       j['country']?.toString(),
      locSource:     j['loc_source']?.toString(),
      isApproximate: j['is_approximate'] == true || j['is_approximate'] == 1 || j['is_approximate'] == 'true',
      locationUpdatedAt: parseDate(j['location_updated_at']),
    );
  }
}
