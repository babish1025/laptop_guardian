import '../models/device.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/command.dart';
import 'api_service.dart';

/// All device-related API calls.
class DeviceService {
  final ApiService _api;
  DeviceService(this._api);

  // ── Devices ───────────────────────────────────────────────────────────────

  Future<List<DeviceModel>> listDevices() async {
    final res = await _api.get('/api/devices');
    if (res['success'] != true) return [];
    final list = res['devices'] as List<dynamic>? ?? [];
    return list
        .map((j) => DeviceModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> deviceDetail(String deviceId) async {
    final res = await _api.get('/api/devices/$deviceId');
    if (res['success'] != true) return null;
    return res;
  }

  // ── Pairing ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generatePairingCode() async =>
      _api.post('/api/devices/pairing-code');

  Future<bool> removeDevice(String deviceId) async {
    final res = await _api.delete('/api/devices/$deviceId');
    return res['success'] == true;
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendCommand(
      String deviceId, String command) async =>
      _api.post('/api/commands', body: {
        'device_id': deviceId,
        'command': command,
      });

  Future<List<CommandModel>> commandHistory(String deviceId) async {
    final res = await _api.get('/api/commands/history/$deviceId');
    if (res['success'] != true) return [];
    final list = res['commands'] as List<dynamic>? ?? [];
    return list
        .map((j) => CommandModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Activity ──────────────────────────────────────────────────────────────

  Future<List<ActivityModel>> activityHistory(
      String deviceId, {String period = '7d'}) async {
    final res = await _api.get(
      '/api/activity/$deviceId',
      params: {'period': period},
    );
    if (res['success'] != true) return [];
    final list = res['activities'] as List<dynamic>? ?? [];
    return list
        .map((j) => ActivityModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<LocationModel?> latestLocation(String deviceId) async {
    final res = await _api.get('/api/location/$deviceId');
    if (res['success'] != true) return null;
    final locJson = res['location'] as Map<String, dynamic>?;
    if (locJson == null) return null;
    return LocationModel.fromJson(locJson);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> notifications({int limit = 50}) async {
    final res = await _api.get('/api/notifications', params: {'limit': '$limit'});
    if (res['success'] != true) return [];
    return List<Map<String, dynamic>>.from(
        res['notifications'] as List<dynamic>? ?? []);
  }

  Future<int> unreadCount() async {
    final res = await _api.get('/api/notifications/unread-count');
    return (res['count'] as int?) ?? 0;
  }

  Future<void> markAllRead() async {
    await _api.post('/api/notifications/read-all');
  }
}
