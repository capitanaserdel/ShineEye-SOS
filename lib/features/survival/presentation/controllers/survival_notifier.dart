import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

enum SurvivalStatus { initial, loading, success, error }

class SurvivalState {
  final SurvivalStatus status;
  final List<dynamic> guides;
  final String language; // en, ha, yo, ig
  final String? errorMessage;

  SurvivalState({
    required this.status,
    required this.guides,
    required this.language,
    this.errorMessage,
  });

  factory SurvivalState.initial() => SurvivalState(status: SurvivalStatus.initial, guides: [], language: 'en');

  SurvivalState copyWith({
    SurvivalStatus? status,
    List<dynamic>? guides,
    String? language,
    String? errorMessage,
  }) {
    return SurvivalState(
      status: status ?? this.status,
      guides: guides ?? this.guides,
      language: language ?? this.language,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SurvivalNotifier extends StateNotifier<SurvivalState> {
  final ApiClient _apiClient;

  SurvivalNotifier(this._apiClient) : super(SurvivalState.initial()) {
    fetchGuides();
  }

  // Fetch survival guides filtered by language
  Future<void> fetchGuides({String? lang}) async {
    final languageToFetch = lang ?? state.language;
    state = state.copyWith(status: SurvivalStatus.loading, language: languageToFetch);
    try {
      final response = await _apiClient.get('/survival-guides', queryParameters: {
        'language': languageToFetch,
      });
      final List<dynamic> data = response.data;
      state = state.copyWith(status: SurvivalStatus.success, guides: data);
    } catch (e) {
      state = state.copyWith(status: SurvivalStatus.error, errorMessage: e.toString());
    }
  }

  // Change language dynamically
  Future<void> changeLanguage(String newLanguage) async {
    await fetchGuides(lang: newLanguage);
  }
}

final survivalProvider = StateNotifierProvider<SurvivalNotifier, SurvivalState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SurvivalNotifier(apiClient);
});
