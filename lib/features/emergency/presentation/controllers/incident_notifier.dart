import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

enum IncidentStatus { initial, loading, success, error }

class IncidentState {
  final IncidentStatus status;
  final List<dynamic> incidents;
  final String? errorMessage;

  IncidentState({
    required this.status,
    required this.incidents,
    this.errorMessage,
  });

  factory IncidentState.initial() => IncidentState(status: IncidentStatus.initial, incidents: []);

  IncidentState copyWith({
    IncidentStatus? status,
    List<dynamic>? incidents,
    String? errorMessage,
  }) {
    return IncidentState(
      status: status ?? this.status,
      incidents: incidents ?? this.incidents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class IncidentNotifier extends StateNotifier<IncidentState> {
  final ApiClient _apiClient;

  IncidentNotifier(this._apiClient) : super(IncidentState.initial()) {
    fetchIncidents();
  }

  // Fetch all incidents from backend
  Future<void> fetchIncidents() async {
    state = state.copyWith(status: IncidentStatus.loading);
    try {
      final response = await _apiClient.get('/incidents');
      final List<dynamic> data = response.data;
      state = state.copyWith(status: IncidentStatus.success, incidents: data);
    } catch (e) {
      state = state.copyWith(status: IncidentStatus.error, errorMessage: e.toString());
    }
  }

  // Submit a new incident report
  Future<bool> reportIncident({
    required String type,
    required String description,
    required double latitude,
    required double longitude,
    required String urgencyLevel,
    required bool isAnonymous,
    List<String>? mediaUrls,
  }) async {
    state = state.copyWith(status: IncidentStatus.loading);
    try {
      await _apiClient.post('/incidents', data: {
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'urgency_level': urgencyLevel,
        'is_anonymous': isAnonymous,
        if (mediaUrls != null) 'media_urls': mediaUrls,
      });
      // Refresh feed
      await fetchIncidents();
      return true;
    } catch (e) {
      state = state.copyWith(status: IncidentStatus.error, errorMessage: e.toString());
      return false;
    }
  }
}

final incidentProvider = StateNotifierProvider<IncidentNotifier, IncidentState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return IncidentNotifier(apiClient);
});
