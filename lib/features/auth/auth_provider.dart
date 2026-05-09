import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';

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
  
  // Local mock database for development
  static final List<Map<String, dynamic>> _mockUsers = [
    {'name': 'Admin User', 'email': 'admin@farmnex.com', 'password': 'admin123', 'role': 'admin'},
  ];

  AuthNotifier(this._apiService) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadMockUsers();
    await _loadToken();
  }

  Future<void> _loadMockUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final mockUsersJson = prefs.getStringList('mock_users');
    if (mockUsersJson != null) {
      _mockUsers.clear();
      _mockUsers.addAll([
        {'name': 'Admin User', 'email': 'admin@farmnex.com', 'password': 'admin123', 'role': 'admin'},
      ]);
      for (var userJson in mockUsersJson) {
        final user = Map<String, dynamic>.from(jsonDecode(userJson));
        if (!_mockUsers.any((u) => u['email'] == user['email'])) {
          _mockUsers.add(user);
        }
      }
    }
  }

  Future<void> _saveMockUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final mockUsersJson = _mockUsers
        .where((u) => u['email'] != 'admin@farmnex.com') // Don't save the default admin
        .map((u) => jsonEncode(u))
        .toList();
    await prefs.setStringList('mock_users', mockUsersJson);
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      state = state.copyWith(token: token);
      // Optionally fetch profile
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Try real API first
      try {
        final response = await _apiService.post(ApiConstants.login, data: {
          'email': email,
          'password': password,
        });

        final token = response.data['token'];
        final userData = response.data;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        state = state.copyWith(isLoading: false, token: token, user: userData);
        return true;
      } catch (apiError) {
        // 2. Fallback to mock if API fails (e.g. server down or DB down)
        final user = _mockUsers.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
          orElse: () => {},
        );

        if (user.isNotEmpty) {
          state = state.copyWith(
            isLoading: false, 
            token: 'mock-token-${user['role']}', 
            user: user
          );
          return true;
        }
        
        state = state.copyWith(isLoading: false, error: 'Invalid email or password');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error');
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Try real API
      try {
        final response = await _apiService.post(ApiConstants.register, data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        });

        final token = response.data['token'];
        final userData = response.data;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        state = state.copyWith(isLoading: false, token: token, user: userData);
        return true;
      } catch (apiError) {
        // 2. Fallback to mock
        if (_mockUsers.any((u) => u['email'] == email)) {
          state = state.copyWith(isLoading: false, error: 'User already exists');
          return false;
        }

        final newUser = {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        };
        _mockUsers.add(newUser);
        await _saveMockUsers();

        state = state.copyWith(
          isLoading: false, 
          token: 'mock-token-$role', 
          user: newUser
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = AuthState();
  }

  // Restore the getter for the usersProvider
  List<Map<String, dynamic>> get allUsers => List.unmodifiable(_mockUsers);
}

final usersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider.notifier);
  return auth.allUsers;
});
