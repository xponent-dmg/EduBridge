import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, this.authToken}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? authToken;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$backendBaseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${authToken!}';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final url = _uri(path, query);
    // ignore: avoid_print
    print('[ApiClient] GET $url');
    final res = await _http.get(url, headers: _headers());
    // ignore: avoid_print
    print('[ApiClient] <- ${res.statusCode} ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final url = _uri(path);
    // ignore: avoid_print
    print('[ApiClient] POST $url body=${jsonEncode(body ?? {})}');
    final res = await _http.post(url, headers: _headers(), body: jsonEncode(body ?? {}));
    // ignore: avoid_print
    print('[ApiClient] <- ${res.statusCode} ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    return _decode(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final url = _uri(path);
    // ignore: avoid_print
    print('[ApiClient] PATCH $url body=${jsonEncode(body ?? {})}');
    final res = await _http.patch(url, headers: _headers(), body: jsonEncode(body ?? {}));
    // ignore: avoid_print
    print('[ApiClient] <- ${res.statusCode} ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    // ignore: avoid_print
    print('[ApiClient] ERROR ${res.statusCode} $decoded');
    throw ApiException(statusCode: res.statusCode, body: decoded);
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  String toString() => 'ApiException($statusCode, $body)';
}
