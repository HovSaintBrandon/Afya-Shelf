import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    if (await _api.hasToken) {
      print('🔄 [AUTH] Token found, attempting auto-login...');
      await fetchProfile();
    } else {
      print('ℹ️ [AUTH] No token found for auto-login');
    }
  }

  Future<bool> login(String username, String password) async {
    print('🔑 [AUTH] Login attempt for: $username');
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post(ApiConfig.authLogin, {
        'username': username,
        'password': password,
      });
      
      final accessToken = data['accessToken'] ?? data['token'];
      final refreshToken = data['refreshToken'];
      
      if (accessToken != null && refreshToken != null) {
        await _api.setTokens(accessToken, refreshToken);
      } else if (accessToken != null) {
        await _api.setTokens(accessToken, '');
      }

      _user = User.fromJson(data['user'] ?? data);
      print('✅ [AUTH] Login successful: ${_user?.username} (Role: ${_user?.role})');
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [AUTH] Login failed: $e');
      _error = e is ApiException ? e.message : 'Login failed';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    print('👤 [AUTH] Fetching profile...');
    try {
      final data = await _api.get(ApiConfig.authMe);
      _user = User.fromJson(data);
      print('✅ [AUTH] Profile fetched: ${_user?.username}');
      notifyListeners();
    } catch (e) {
      print('⚠️ [AUTH] Profile fetch failed: $e');
    }
  }

  Future<bool> switchClinic(String clinicId) async {
    print('🏥 [AUTH] Switching to clinic: $clinicId');
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.put(ApiConfig.authSwitchClinic, {'clinicId': clinicId});
      if (data != null && (data['user'] != null || data['_id'] != null)) {
        _user = User.fromJson(data['user'] ?? data);
      } else {
        await fetchProfile();
      }
      print('✅ [AUTH] Switch successful. New clinic: ${_user?.clinicId}');
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [AUTH] Switch failed: $e');
      _error = e is ApiException ? e.message : 'Switch failed';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 [AUTH] Logging out user: ${_user?.username}');
    try {
      final rt = await _api.refreshToken;
      if (rt != null) {
        await _api.post(ApiConfig.authLogout, {'refreshToken': rt});
      }
    } catch (e) {
      print('⚠️ [AUTH] Server-side logout failed: $e');
    }
    await _api.clearToken();
    _user = null;
    print('✅ [AUTH] Local session cleared');
    notifyListeners();
  }

  Future<bool> register(String username, String password, String confirmPassword, String clinicName) async {
    print('📝 [AUTH] Registration attempt for: $username (Clinic: $clinicName)');
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post(ApiConfig.authRegister, {
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'clinic_name': clinicName,
      });
      print('✅ [AUTH] Registration successful');
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [AUTH] Registration failed: $e');
      _error = e is ApiException ? e.message : 'Registration failed';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addWorker(String username, String password, String role, String clinicName) async {
    print('👷 [AUTH] Adding worker: $username (Role: $role)');
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post(ApiConfig.authWorkers, {
        'username': username,
        'password': password,
        'role': role,
        'clinic_name': clinicName,
      });
      print('✅ [AUTH] Worker added successfully');
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [AUTH] Add worker failed: $e');
      _error = e is ApiException ? e.message : 'Failed to add worker';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
