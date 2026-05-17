import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

enum AlertStatus { initial, loading, success, error }

class AlertState {
  final AlertStatus status;
  final List<dynamic> alerts;
  final String? errorMessage;

  AlertState({
    required this.status,
    required this.alerts,
    this.errorMessage,
  });

  factory AlertState.initial() => AlertState(status: AlertStatus.initial, alerts: []);

  AlertState copyWith({
    AlertStatus? status,
    List<dynamic>? alerts,
    String? errorMessage,
  }) {
    return AlertState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AlertNotifier extends StateNotifier<AlertState> {
  final ApiClient _apiClient;

  AlertNotifier(this._apiClient) : super(AlertState.initial()) {
    fetchAlerts();
  }

  // Fetch all geo-fenced safety warning alerts
  Future<void> fetchAlerts() async {
    state = state.copyWith(status: AlertStatus.loading);
    try {
      final response = await _apiClient.get('/alerts');
      final List<dynamic> data = response.data;
      state = state.copyWith(status: AlertStatus.success, alerts: data);
    } catch (e) {
      state = state.copyWith(status: AlertStatus.error, errorMessage: e.toString());
    }
  }

  // Create an alert (usually done by responders/admins)
  Future<bool> createAlert({
    required String title,
    required String message,
    required String type,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    state = state.copyWith(status: AlertStatus.loading);
    try {
      await _apiClient.post('/alerts', data: {
        'title': title,
        'message': message,
        'type': type,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radius_km': radiusKm,
      });
      await fetchAlerts();
      return true;
    } catch (e) {
      state = state.copyWith(status: AlertStatus.error, errorMessage: e.toString());
      return false;
    }
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AlertNotifier(apiClient);
});
