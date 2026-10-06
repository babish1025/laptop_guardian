import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Low-level HTTP client.
/// Automatically attaches the stored Bearer token to every request.
class ApiService {
  final StorageService _store;
  ApiService(this._store);

  // ── Request helpers ───────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _store.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? params]) {
    final base = Uri.parse(ApiConfig.baseUrl);
    return base.replace(
      path: '${base.path}$path'.replaceAll('//', '/'),
      queryParameters: params,
    );
  }

  Future<Map<String, dynamic>> _decode(http.Response resp) async {
    if (resp.body.isEmpty) return {};
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': resp.body};
    }
  }

  // ── Public request methods ────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? params,
  }) async {
    try {
      final resp = await http
          .get(_uri(path, params), headers: await _headers(json: false))
          .timeout(ApiConfig.timeout);
      return await _decode(resp);
    } on SocketException {
      return {'success': false, 'error': 'Cannot reach server. Check your network.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final resp = await http
          .post(
            _uri(path),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);
      return await _decode(resp);
    } on SocketException {
      return {'success': false, 'error': 'Cannot reach server. Check your network.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final resp = await http
          .delete(_uri(path), headers: await _headers(json: false))
          .timeout(ApiConfig.timeout);
      return await _decode(resp);
    } on SocketException {
      return {'success': false, 'error': 'Cannot reach server. Check your network.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
