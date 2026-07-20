import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_store.dart';

class BackendApi {
  BackendApi._();

  static const String baseUrl = String.fromEnvironment(
    'GREENRES_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<bool> checkHealth({http.Client? client}) async {
    try {
      final response = await (client ?? http.Client())
          .get(_uri('/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Generic authenticated GET for endpoints that return a single object
  /// (e.g. /rewards/wallet, /coach/weekly) rather than a list.
  static Future<Map<String, dynamic>> get(String path,
      {http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).get(
        _uri(path),
        headers: await _headers(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return const {};
    });
  }

  static Future<Map<String, dynamic>?> getOrNull(String path,
      {http.Client? client}) async {
    try {
      return await get(path, client: client);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getList(String path,
      {http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).get(
        _uri(path),
        headers: await _headers(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return const [];
    });
  }

  static Future<List<Map<String, dynamic>>?> getListOrNull(String path,
      {http.Client? client}) async {
    try {
      return await getList(path, client: client);
    } catch (_) {
      return null;
    }
  }

  /// Generic authenticated POST for write actions (join, submit, create,
  /// send). Returns the decoded `data` payload as a Map — use [postForList]
  /// if the endpoint returns a list instead.
  static Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic> body = const {}, http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      if (response.body.isEmpty) return const {};
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return const {};
    });
  }

  static Future<Map<String, dynamic>?> postOrNull(String path,
      {Map<String, dynamic> body = const {}, http.Client? client}) async {
    try {
      return await post(path, body: body, client: client);
    } catch (_) {
      return null;
    }
  }

  /// Generic authenticated PATCH for partial-update endpoints (e.g.
  /// /profiles/me).
  static Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic> body = const {}, http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).patch(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      if (response.body.isEmpty) return const {};
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return const {};
    });
  }

  static Future<Map<String, dynamic>?> patchOrNull(String path,
      {Map<String, dynamic> body = const {}, http.Client? client}) async {
    try {
      return await patch(path, body: body, client: client);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> signIn(String email, String password,
      {http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).post(
        _uri('/auth/login'),
        headers: await _headers(),
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! Map) {
        throw Exception('Invalid authentication response');
      }
      return Map<String, dynamic>.from(data);
    });
  }

  static Future<Map<String, dynamic>> signUp(String email, String password,
      {String? fullName, http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).post(
        _uri('/auth/signup'),
        headers: await _headers(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'full_name': fullName?.trim(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! Map) {
        throw Exception('Invalid authentication response');
      }
      return Map<String, dynamic>.from(data);
    });
  }

  static Future<Map<String, dynamic>> getCurrentUser(
      {http.Client? client}) async {
    return _handleResponse(() async {
      final response = await (client ?? http.Client()).get(
        _uri('/auth/me'),
        headers: await _headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _clearSessionOnUnauthorized(response);
        throw Exception(_messageFromResponse(response));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! Map) {
        throw Exception('Invalid user response');
      }
      return Map<String, dynamic>.from(data);
    });
  }

  static Future<T> _handleResponse<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }
      rethrow;
    }
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SessionStore.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<void> clearSession() => SessionStore.clear();

  /// For endpoints that return raw bytes (e.g. audio) instead of JSON.
  /// Returns null on any failure — including a 503 "not configured"
  /// response — so callers can fall back gracefully rather than crash.
  static Future<List<int>?> postForBytes(String path,
      {Map<String, dynamic> body = const {}, http.Client? client}) async {
    try {
      final response = await (client ?? http.Client()).post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  static void _clearSessionOnUnauthorized(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Best-effort: don't block the error path on disk I/O.
      SessionStore.clear();
    }
  }

  static String _messageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] is String) {
          return decoded['message'].toString();
        }
        if (decoded['error'] is String) {
          return decoded['error'].toString();
        }
      }
    } catch (_) {}
    return 'Request failed: ${response.statusCode}';
  }
}
