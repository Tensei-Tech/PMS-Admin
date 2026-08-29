import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized secure storage service for PMS Admin Console.
/// Uses Android Keystore on Android, iOS Keychain on iOS,
/// and SharedPreferences with in-memory caching on Web/fallback.
class SecureStorage {
  SecureStorage._();

  static final Map<String, String> _memoryCache = {};

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    webOptions: WebOptions(
      dbName: 'pms_admin_secure_storage',
      publicKey: 'pms_admin_secure_key',
    ),
  );

  static final SecureStorage instance = SecureStorage._();

  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await delete(key: key);
      return;
    }
    _memoryCache[key] = value;
    try {
      if (!kIsWeb) {
        await _storage.write(key: key, value: value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sec_$key', value);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] write error for $key: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sec_$key', value);
      } catch (_) {}
    }
  }

  Future<String?> read({required String key}) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      if (!kIsWeb) {
        final val = await _storage.read(key: key);
        if (val != null) {
          _memoryCache[key] = val;
          return val;
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString('sec_$key');
      if (val != null) {
        _memoryCache[key] = val;
      }
      return val;
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] read error for $key: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        final val = prefs.getString('sec_$key');
        if (val != null) _memoryCache[key] = val;
        return val;
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> delete({required String key}) async {
    _memoryCache.remove(key);
    try {
      if (!kIsWeb) {
        await _storage.delete(key: key);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sec_$key');
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] delete error for $key: $e');
    }
  }

  Future<void> deleteAll() async {
    _memoryCache.clear();
    try {
      if (!kIsWeb) {
        await _storage.deleteAll();
      }
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('sec_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] deleteAll error: $e');
    }
  }
}

