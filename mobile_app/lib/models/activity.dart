class ActivityModel {
  final int id;
  final String deviceId;
  final String eventType;
  final String? eventDetails;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;

  const ActivityModel({
    required this.id,
    required this.deviceId,
    required this.eventType,
    this.eventDetails,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.locationLabel,
  });

  String get eventIcon {
    switch (eventType) {
      case 'STARTUP': return '🟢';
      case 'SHUTDOWN': return '🔴';
      case 'RESTART': return '🔄';
      case 'LOCK': return '🔒';
      case 'UNLOCK': return '🔓';
      case 'SLEEP': return '😴';
      case 'WAKE': return '☀️';
      case 'UNEXPECTED_OFFLINE': return '⚠️';
      default: return '📋';
    }
  }

  String get eventLabel {
    switch (eventType) {
      case 'STARTUP': return 'Laptop Started';
      case 'SHUTDOWN': return 'Laptop Shutdown';
      case 'RESTART': return 'Laptop Restarted';
      case 'LOCK': return 'Laptop Locked';
      case 'UNLOCK': return 'Laptop Unlocked';
      case 'SLEEP': return 'Laptop Sleeping';
      case 'WAKE': return 'Laptop Woke Up';
      case 'UNEXPECTED_OFFLINE': return 'Unexpected Disconnect';
      default: return eventType;
    }
  }

  factory ActivityModel.fromJson(Map<String, dynamic> j) {
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

    return ActivityModel(
      id:            parseInt(j['id']) ?? 0,
      deviceId:      j['device_id']?.toString() ?? '',
      eventType:     j['event_type']?.toString() ?? '',
      eventDetails:  j['event_details']?.toString(),
      createdAt:     parseDate(j['created_at']),
      latitude:      parseDouble(j['latitude']),
      longitude:     parseDouble(j['longitude']),
      locationLabel: j['location_label']?.toString(),
    );
  }
}
