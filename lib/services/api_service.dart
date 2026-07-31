import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/flow.dart';

/// Connects to the VPS backend (see /mnt/user-data/outputs/proxyapp/backend/main.py).
///
/// [baseUrl] should be like `144.172.109.109:8000` (no scheme, no trailing slash) -
/// scheme is derived per-call (http/ws vs https/wss) based on [useTls].
class ApiService {
  final String host;
  final int port;
  final String controlToken;
  final bool useTls;

  ApiService({
    required this.host,
    required this.port,
    required this.controlToken,
    this.useTls = false,
  });

  String get _httpScheme => useTls ? 'https' : 'http';
  String get _wsScheme => useTls ? 'wss' : 'ws';

  Uri _httpUri(String path, [Map<String, String>? query]) =>
      Uri(scheme: _httpScheme, host: host, port: port, path: path, queryParameters: query);

  Uri _wsUri(String path, Map<String, String> query) =>
      Uri(scheme: _wsScheme, host: host, port: port, path: path, queryParameters: query);

  Map<String, String> get _authHeaders => {'Authorization': 'Bearer $controlToken'};

  /// Fetch historical flows. [hostFilter] does a substring match server-side.
  Future<List<Flow>> fetchFlows({int limit = 100, String? hostFilter}) async {
    final query = <String, String>{'limit': '$limit'};
    if (hostFilter != null && hostFilter.isNotEmpty) query['host'] = hostFilter;

    final resp = await http.get(_httpUri('/flows', query), headers: _authHeaders);
    if (resp.statusCode == 401) {
      throw ApiAuthException('Control token rejected by backend');
    }
    if (resp.statusCode != 200) {
      throw ApiException('GET /flows failed: ${resp.statusCode} ${resp.body}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((e) => Flow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Flow> fetchFlow(String id) async {
    final resp = await http.get(_httpUri('/flows/$id'), headers: _authHeaders);
    if (resp.statusCode == 401) {
      throw ApiAuthException('Control token rejected by backend');
    }
    if (resp.statusCode == 404) {
      throw ApiException('Flow not found');
    }
    if (resp.statusCode != 200) {
      throw ApiException('GET /flows/$id failed: ${resp.statusCode}');
    }
    return Flow.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Opens the live flow stream. Caller owns the returned channel and must
  /// call [WebSocketChannel.sink.close] when done (e.g. in dispose()).
  WebSocketChannel connectStream() {
    final uri = _wsUri('/stream', {'token': controlToken});
    return WebSocketChannel.connect(uri);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiAuthException extends ApiException {
  ApiAuthException(super.message);
}
