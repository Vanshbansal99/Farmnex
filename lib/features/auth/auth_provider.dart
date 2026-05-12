import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

class AuthState {
  final bool isLoading;
  final String? token;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.token, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? token, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  SharedPreferences? _prefs;

  AuthNotifier(this._apiService) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadToken();
  }

  Future<void> _loadToken() async {
    final token = _prefs?.getString('token');
    if (token != null) {
      try {
        final response = await _apiService.get(ApiConstants.profile, 
          token: token
        ).timeout(const Duration(seconds: 10));
        state = state.copyWith(token: token, user: response.data);
      } catch (e) {
        // Token might be expired or invalid
        await _prefs?.remove('token');
        state = AuthState();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      }).timeout(const Duration(seconds: 10));

      final token = response.data['token'];
      final userData = response.data;
      
      await _prefs?.setString('token', token);

      state = state.copyWith(isLoading: false, token: token, user: userData);
      return true;
    } catch (e) {
      String errorMessage = 'Invalid email or password';
      if (e is DioException && e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Server connection timed out';
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    print('📝 Attempting Signup for: $email');
    try {
      final response = await _apiService.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      print('✅ Signup API Success');
      final token = response.data['token'];
      final userData = response.data;
      
      // Ensure prefs is ready
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString('token', token);

      state = state.copyWith(isLoading: false, token: token, user: userData);
      print('🎉 Signup state updated successfully');
      return true;
    } catch (e) {
      print('❌ Signup API Error: $e');
      String errorMessage = 'Signup failed';
      if (e is DioException && e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs?.remove('token');
    state = AuthState();
  }

  // Clear any existing errors
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}
