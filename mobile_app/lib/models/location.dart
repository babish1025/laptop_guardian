class LocationModel {
  final int? id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String source;       // GPS | WIFI | IP | UNKNOWN | CELL
  final String? city;
  final String? state;
  final String? country;
  final String? isp;
  final bool isApproximate;
  final DateTime? createdAt;

  const LocationModel({
    this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.source,
    this.city,
    this.state,
    this.country,
    this.isp,
    required this.isApproximate,
    this.createdAt,
  });

  String get displayLabel {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  String get fullAddress => displayLabel;
  bool get hasCoordinates => latitude != 0.0 || longitude != 0.0;
  double? get accuracyMeters => accuracy;
  String? get region => state;

  String get accuracyLabel {
    if (accuracy == null) return isApproximate ? 'Approximate (IP)' : 'Unknown accuracy';
    final km = accuracy! / 1000;
    if (km < 1) return '±${accuracy!.round()} m';
    return '±${km.toStringAsFixed(0)} km';
  }

  String get mapsUrl =>
      'https://www.google.com/maps?q=$latitude,$longitude';

  factory LocationModel.fromJson(Map<String, dynamic> j) {
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

    return LocationModel(
      id:            parseInt(j['id']),
      deviceId:      j['device_id']?.toString() ?? '',
      latitude:      parseDouble(j['latitude']) ?? 0.0,
      longitude:     parseDouble(j['longitude']) ?? 0.0,
      accuracy:      parseDouble(j['accuracy']),
      source:        j['source']?.toString() ?? 'UNKNOWN',
      city:          j['city']?.toString(),
      state:         j['state']?.toString(),
      country:       j['country']?.toString(),
      isp:           j['isp']?.toString(),
      isApproximate: j['is_approximate'] == true || j['is_approximate'] == 1 || j['is_approximate'] == 'true',
      createdAt:     parseDate(j['created_at']),
    );
  }
}
