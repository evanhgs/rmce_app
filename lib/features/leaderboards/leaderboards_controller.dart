import 'package:flutter/foundation.dart';

import '../routes/route_models.dart';
import 'leaderboard_models.dart';
import 'leaderboards_repository.dart';

class LeaderboardsState {
  const LeaderboardsState({
    required this.isLoading,
    required this.routeLeaderboard,
    required this.globalSpeedLeaderboard,
    this.selectedRoute,
    this.errorMessage,
  });

  final bool isLoading;
  final List<LeaderboardEntry> routeLeaderboard;
  final List<LeaderboardEntry> globalSpeedLeaderboard;
  final RouteModel? selectedRoute;
  final String? errorMessage;

  const LeaderboardsState.initial()
      : isLoading = false,
        routeLeaderboard = const [],
        globalSpeedLeaderboard = const [],
        selectedRoute = null,
        errorMessage = null;

  LeaderboardsState copyWith({
    bool? isLoading,
    List<LeaderboardEntry>? routeLeaderboard,
    List<LeaderboardEntry>? globalSpeedLeaderboard,
    RouteModel? selectedRoute,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardsState(
      isLoading: isLoading ?? this.isLoading,
      routeLeaderboard: routeLeaderboard ?? this.routeLeaderboard,
      globalSpeedLeaderboard:
          globalSpeedLeaderboard ?? this.globalSpeedLeaderboard,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderboardsController {
  LeaderboardsController({required LeaderboardsRepository repository})
      : _repository = repository;

  final LeaderboardsRepository _repository;
  final ValueNotifier<LeaderboardsState> state =
      ValueNotifier(const LeaderboardsState.initial());

  Future<void> loadGlobal() async {
    state.value = state.value.copyWith(isLoading: true, clearError: true);
    try {
      final global = await _repository.getGlobalSpeedLeaderboard();
      state.value = state.value.copyWith(
        isLoading: false,
        globalSpeedLeaderboard: global,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> selectRoute(RouteModel route) async {
    state.value = state.value.copyWith(
      isLoading: true,
      selectedRoute: route,
      clearError: true,
    );
    try {
      final leaderboard = await _repository.getRouteLeaderboard(route.id);
      state.value = state.value.copyWith(
        isLoading: false,
        routeLeaderboard: leaderboard,
        selectedRoute: route,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}
