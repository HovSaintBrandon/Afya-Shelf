import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _refreshToken;
  bool _isRefreshing = false;

  Future<String?> get token async {
    _token ??= await _storage.read(key: 'auth_token');
    return _token;
  }

  Future<String?> get refreshToken async {
    _refreshToken ??= await _storage.read(key: 'refresh_token');
    return _refreshToken;
  }

  Future<bool> get hasToken async => (await token) != null;

  Future<void> setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<Map<String, String>> get _headers async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<dynamic> get(String url) async {
    print('🚀 [API REQ] GET: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: await _headers);
      return await _handleResponse(response, () => get(url));
    } catch (e) {
      print('❌ [API ERR] GET $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    print('🚀 [API REQ] POST: $url | BODY: $body');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _headers,
        body: jsonEncode(body),
      );
      return await _handleResponse(response, () => post(url, body));
    } catch (e) {
      print('❌ [API ERR] POST $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    print('🚀 [API REQ] PUT: $url | BODY: $body');
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: await _headers,
        body: jsonEncode(body),
      );
      return await _handleResponse(response, () => put(url, body));
    } catch (e) {
      print('❌ [API ERR] PUT $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }

  Future<dynamic> postMultipart(String url, String filePath, String field) async {
    print('🚀 [API REQ] MULTIPART: $url | FILE: $filePath');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(await _headers);
      request.files.add(await http.MultipartFile.fromPath(field, filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return await _handleResponse(response, () => postMultipart(url, filePath, field));
    } catch (e) {
      print('❌ [API ERR] MULTIPART $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }

  Future<dynamic> _handleResponse(http.Response response, Future<dynamic> Function() retry) async {
    print('📥 [API RES] ${response.request?.method} ${response.request?.url.path} | STATUS: ${response.statusCode} | BODY: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 && !_isRefreshing) {
      print('🔄 [API AUTH] 401 Unauthorized - Attempting token refresh...');
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        print('✅ [API AUTH] Token refresh successful, retrying request...');
        return await retry();
      } else {
        print('🛑 [API AUTH] Token refresh failed');
        throw ApiException(statusCode: 401, message: 'Session expired');
      }
    } else {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Request failed',
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    _isRefreshing = true;
    try {
      final rt = await refreshToken;
      if (rt == null) {
        print('⚠️ [API AUTH] No refresh token available');
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.authRefresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setTokens(data['accessToken'], data['refreshToken'] ?? rt);
        _isRefreshing = false;
        return true;
      }
    } catch (e) {
      print('❌ [API AUTH] Refresh exception: $e');
    }
    _isRefreshing = false;
    return false;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
