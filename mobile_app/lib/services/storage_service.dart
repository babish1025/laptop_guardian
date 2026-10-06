import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';

/// Persists auth token and user info in the device's secure keystore.
/// No sensitive data is ever written to plain SharedPreferences.
class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'lg_auth_token';
  static const _keyUser  = 'lg_user';

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> clearToken() => _storage.delete(key: _keyToken);

  Future<void> saveUser(UserModel user) =>
      _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));

  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
