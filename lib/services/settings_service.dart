import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kHost = 'vps_host';
  static const _kPort = 'vps_port';
  static const _kToken = 'control_token';
  static const _kTls = 'use_tls';

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'host': prefs.getString(_kHost) ?? '',
      'port': prefs.getInt(_kPort) ?? 8000,
      'token': prefs.getString(_kToken) ?? '',
      'useTls': prefs.getBool(_kTls) ?? false,
    };
  }

  Future<void> save({
    required String host,
    required int port,
    required String token,
    required bool useTls,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHost, host);
    await prefs.setInt(_kPort, port);
    await prefs.setString(_kToken, token);
    await prefs.setBool(_kTls, useTls);
  }

  Future<bool> isConfigured() async {
    final s = await load();
    return (s['host'] as String).isNotEmpty && (s['token'] as String).isNotEmpty;
  }
}
