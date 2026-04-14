import 'package:flutter/foundation.dart';

import 'challenge_models.dart';
import 'challenges_repository.dart';

class ChallengesState {
  const ChallengesState({
    required this.isLoading,
    required this.availableChallenges,
    this.feedbackMessage,
    this.errorMessage,
  });

  final bool isLoading;
  final List<ChallengeModel> availableChallenges;
  final String? feedbackMessage;
  final String? errorMessage;

  const ChallengesState.initial()
      : isLoading = false,
        availableChallenges = const [],
        feedbackMessage = null,
        errorMessage = null;

  ChallengesState copyWith({
    bool? isLoading,
    List<ChallengeModel>? availableChallenges,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return ChallengesState(
      isLoading: isLoading ?? this.isLoading,
      availableChallenges: availableChallenges ?? this.availableChallenges,
      feedbackMessage:
          clearFeedback ? null : feedbackMessage ?? this.feedbackMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ChallengesController {
  ChallengesController({required ChallengesRepository repository})
      : _repository = repository;

  final ChallengesRepository _repository;
  final ValueNotifier<ChallengesState> state =
      ValueNotifier(const ChallengesState.initial());

  Future<void> load() async {
    state.value = state.value.copyWith(isLoading: true, clearError: true);
    try {
      final challenges = await _repository.getAvailableChallenges();
      state.value = state.value.copyWith(
        isLoading: false,
        availableChallenges: challenges,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> createChallenge({
    required int routeId,
    int? challengedId,
  }) async {
    try {
      await _repository.createChallenge(
        routeId: routeId,
        challengedId: challengedId,
      );
      state.value = state.value.copyWith(
        feedbackMessage: 'Défi envoyé.',
        clearError: true,
      );
      await load();
    } catch (error) {
      state.value = state.value.copyWith(
        errorMessage: error.toString(),
      );
    }
  }
}
