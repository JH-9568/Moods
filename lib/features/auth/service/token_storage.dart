import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 토큰/자동로그인 정보를 보관하는 래퍼
class TokenStorage {
  static const _kAccess       = 'ACCESS_TOKEN';
  static const _kRefresh      = 'REFRESH_TOKEN';
  static const _kLoginPayload = 'LOGIN_PAYLOAD'; // {email,password} 또는 소셜 payload

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Access ──────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccess, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  // ── Refresh ─────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefresh, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  // ── Auto-login payload (이메일/비번 또는 소셜 식별 정보 등) ─────────────
  Future<void> saveLoginPayload(Map<String, dynamic> payload) async =>
      _storage.write(key: _kLoginPayload, value: jsonEncode(payload));

  Future<dynamic> readLoginPayload() async {
    final raw = await _storage.read(key: _kLoginPayload);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  // ── 전체 삭제 (로그아웃 시) ──────────────────────────────────────────
  Future<void> clearAll() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kLoginPayload);
  }
}
