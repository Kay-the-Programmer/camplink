import 'dart:convert';

import 'package:http/http.dart' as http;

/// Backend base URL. Override at build/run time without editing this file:
///   flutter run --dart-define=API_BASE_URL=https://camplink-api.onrender.com/api
///
/// Defaults below are for LOCAL development:
///   Android emulator:        http://10.0.2.2:8080/api
///   iOS simulator / desktop: http://localhost:8080/api
///   Physical device on LAN:  http://YOUR_PC_LAN_IP:8080/api
const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.20.128.1:8080/api',
);

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static String? _token;

  static void setToken(String? token) => _token = token;
  static String? get token => _token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Uri _uri(String path) => Uri.parse('$_kBaseUrl$path');

  static dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Request failed';
    try {
      final body = jsonDecode(res.body);
      message = body['message'] ?? message;
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    return _parse(res);
  }

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  static Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final res = await http.put(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    _parse(res);
  }

  /// Multipart file upload; returns the response JSON.
  static Future<Map<String, dynamic>> uploadFile(String localPath) async {
    final request = http.MultipartRequest('POST', _uri('/upload'));
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', localPath));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res) as Map<String, dynamic>;
  }

  /// Full URL for a file served by the backend.
  static String fileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_kBaseUrl$path';
  }
}

/// Wraps a Future-based fetch in a Stream that re-fetches on [interval].
/// Drops silently on error so callers using StreamBuilder keep last value.
Stream<T> pollingStream<T>(
  Future<T> Function() fetch, {
  Duration interval = const Duration(seconds: 15),
}) async* {
  while (true) {
    try {
      yield await fetch();
    } catch (_) {}
    await Future.delayed(interval);
  }
}
