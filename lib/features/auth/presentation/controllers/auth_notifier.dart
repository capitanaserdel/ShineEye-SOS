import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_manager.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SessionManager _sessionManager;

  AuthNotifier(this._apiClient, this._sessionManager) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  // Check initial authentication and fetch cached user data
  Future<void> checkAuthStatus() async {
    final loggedIn = await _sessionManager.isLoggedIn();
    if (loggedIn) {
      final user = await _sessionManager.getUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // Register
  Future<void> register(String name, String email, String password, String passwordConfirmation, String? phone) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final String token = response.data['access_token'];
      final Map<String, dynamic> userData = response.data['user'];

      await _sessionManager.saveToken(token);
      await _sessionManager.saveUser(userData);

      state = AuthState(status: AuthStatus.authenticated, user: userData);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.post('/login', data: {
        'email': email,
        'password': password,
      });

      final String token = response.data['access_token'];
      final Map<String, dynamic> userData = response.data['user'];

      await _sessionManager.saveToken(token);
      await _sessionManager.saveUser(userData);

      state = AuthState(status: AuthStatus.authenticated, user: userData);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _apiClient.post('/logout');
    } catch (_) {
      // Proceed with local logout even if remote logout fails due to lack of network
    } finally {
      await _sessionManager.clearSession();
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

// Global Providers
final sessionManagerProvider = Provider<SessionManager>((ref) => SessionManager());

final apiClientProvider = Provider<ApiClient>((ref) {
  final sessionManager = ref.read(sessionManagerProvider);
  return ApiClient(sessionManager);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return AuthNotifier(apiClient, sessionManager);
});
