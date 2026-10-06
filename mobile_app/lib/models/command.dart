class CommandModel {
  final int id;
  final String command;
  final String status;
  final String? result;
  final DateTime? createdAt;
  final DateTime? executedAt;
  final DateTime? expiresAt;

  const CommandModel({
    required this.id,
    required this.command,
    required this.status,
    this.result,
    this.createdAt,
    this.executedAt,
    this.expiresAt,
  });

  String? get errorMessage => status == 'FAILED' ? result : null;

  String get statusLabel {
    switch (status) {
      case 'PENDING':  return 'Sending…';
      case 'RECEIVED': return 'Received';
      case 'EXECUTED': return 'Executed ✓';
      case 'FAILED':   return 'Failed ✗';
      case 'EXPIRED':  return 'Expired';
      default:         return status;
    }
  }

  factory CommandModel.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v as String).toLocal(); } catch (_) { return null; }
    }
    return CommandModel(
      id:          j['id'] as int? ?? 0,
      command:     j['command'] as String? ?? '',
      status:      j['status'] as String? ?? '',
      result:      j['result'] as String?,
      createdAt:   parseDate(j['created_at']),
      executedAt:  parseDate(j['executed_at']),
      expiresAt:   parseDate(j['expires_at']),
    );
  }
}
