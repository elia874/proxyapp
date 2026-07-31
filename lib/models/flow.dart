import 'dart:convert';

/// A single captured HTTP(S) flow (request + response pair).
///
/// The backend sends headers two different ways depending on the endpoint:
///  - GET /flows (history, from SQLite)  -> req_headers/resp_headers as JSON-encoded strings
///  - WS /stream (live push)             -> req_headers/resp_headers as raw JSON objects
/// [_asMap] normalizes both into a Map so the rest of the app doesn't care.
class Flow {
  final String id;
  final double ts;
  final String host;
  final String method;
  final String url;
  final Map<String, dynamic> reqHeaders;
  final String? reqBody;
  final int? respStatus;
  final Map<String, dynamic> respHeaders;
  final String? respBody;
  final int? durationMs;

  Flow({
    required this.id,
    required this.ts,
    required this.host,
    required this.method,
    required this.url,
    required this.reqHeaders,
    this.reqBody,
    this.respStatus,
    required this.respHeaders,
    this.respBody,
    this.durationMs,
  });

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) return v;
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // malformed/empty - fall through to empty map
      }
    }
    return {};
  }

  factory Flow.fromJson(Map<String, dynamic> json) {
    return Flow(
      id: json['id'] as String,
      ts: (json['ts'] as num).toDouble(),
      host: json['host'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      reqHeaders: _asMap(json['req_headers']),
      reqBody: json['req_body'] as String?,
      respStatus: json['resp_status'] as int?,
      respHeaders: _asMap(json['resp_headers']),
      respBody: json['resp_body'] as String?,
      durationMs: json['duration_ms'] as int?,
    );
  }

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch((ts * 1000).round());

  bool get isError => respStatus == null;

  bool get isSuccess => respStatus != null && respStatus! >= 200 && respStatus! < 300;

  bool get isClientOrServerError => respStatus != null && respStatus! >= 400;
}
