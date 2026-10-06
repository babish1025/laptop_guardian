import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final UserModel? user;
  const AuthResult({required this.success, this.error, this.user});
}

/// Handles login, register, logout, and session restoration.
class AuthService {
  final ApiService _api;
  final StorageService _store;

  AuthService(this._api, this._store);

  Future<AuthResult> login(String email, String password) async {
    final res = await _api.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    if (res['success'] == true) {
      final token = res['token'] as String?;
      final userJson = res['user'] as Map<String, dynamic>?;
      if (token != null && userJson != null) {
        await _store.saveToken(token);
        final user = UserModel.fromJson(userJson);
        await _store.saveUser(user);
        return AuthResult(success: true, user: user);
      }
    }
    return AuthResult(
      success: false,
      error: res['error'] as String? ?? 'Login failed.',
    );
  }

  Future<AuthResult> register(String name, String email, String password) async {
    final res = await _api.post(
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    if (res['success'] == true) {
      final token = res['token'] as String?;
      final userJson = res['user'] as Map<String, dynamic>?;
      if (token != null && userJson != null) {
        await _store.saveToken(token);
        final user = UserModel.fromJson(userJson);
        await _store.saveUser(user);
        return AuthResult(success: true, user: user);
      }
    }
    return AuthResult(
      success: false,
      error: res['error'] as String? ?? 'Registration failed.',
    );
  }

  Future<void> logout() async {
    await _api.post('/api/auth/logout');
    await _store.clearAll();
  }

  /// Returns the stored user without a network call (fast, for splash screen).
  Future<UserModel?> restoreSession() async {
    final token = await _store.getToken();
    if (token == null) return null;
    // Validate token still works with a /me call
    final res = await _api.get('/api/auth/me');
    if (res['success'] == true) {
      final userJson = res['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        final user = UserModel.fromJson(userJson);
        await _store.saveUser(user);
        return user;
      }
    }
    // Token expired or invalid — clear it
    await _store.clearAll();
    return null;
  }
}
