import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState {
  final ProfileStatus status;
  final Map<String, dynamic>? profile;
  final String? errorMessage;

  ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  factory ProfileState.initial() => ProfileState(status: ProfileStatus.initial);

  ProfileState copyWith({
    ProfileStatus? status,
    Map<String, dynamic>? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(ProfileState.initial()) {
    fetchProfile();
  }

  // Fetch ICE emergency medical profile
  Future<void> fetchProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await _apiClient.get('/profile');
      final Map<String, dynamic> data = response.data;
      state = state.copyWith(status: ProfileStatus.success, profile: data);
    } catch (e) {
      state = state.copyWith(status: ProfileStatus.error, errorMessage: e.toString());
    }
  }

  // Update ICE emergency medical profile details
  Future<bool> updateProfile({
    required String name,
    required String? phone,
    required String? bloodGroup,
    required String? medicalConditions,
    required List<Map<String, String>> emergencyContacts,
  }) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await _apiClient.put('/profile', data: {
        'name': name,
        'phone': phone,
        'blood_group': bloodGroup,
        'medical_conditions': medicalConditions,
        'emergency_contacts': emergencyContacts,
      });
      final Map<String, dynamic> updatedData = response.data['user'];
      state = state.copyWith(status: ProfileStatus.success, profile: updatedData);
      return true;
    } catch (e) {
      state = state.copyWith(status: ProfileStatus.error, errorMessage: e.toString());
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProfileNotifier(apiClient);
});
