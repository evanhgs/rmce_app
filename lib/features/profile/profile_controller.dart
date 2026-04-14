import 'package:flutter/foundation.dart';

import '../routes/route_models.dart';
import '../routes/routes_repository.dart';
import '../run_session/run_models.dart';
import '../run_session/run_upload_queue_service.dart';

class ProfileState {
  const ProfileState({
    required this.isLoading,
    required this.myRoutes,
    required this.history,
    required this.pendingUploads,
    this.errorMessage,
  });

  final bool isLoading;
  final List<RouteModel> myRoutes;
  final List<RunSummary> history;
  final int pendingUploads;
  final String? errorMessage;

  const ProfileState.initial()
      : isLoading = false,
        myRoutes = const [],
        history = const [],
        pendingUploads = 0,
        errorMessage = null;

  ProfileState copyWith({
    bool? isLoading,
    List<RouteModel>? myRoutes,
    List<RunSummary>? history,
    int? pendingUploads,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      myRoutes: myRoutes ?? this.myRoutes,
      history: history ?? this.history,
      pendingUploads: pendingUploads ?? this.pendingUploads,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileController {
  ProfileController({
    required RoutesRepository routesRepository,
    required RunUploadQueueService queueService,
  })  : _routesRepository = routesRepository,
        _queueService = queueService;

  final RoutesRepository _routesRepository;
  final RunUploadQueueService _queueService;
  final ValueNotifier<ProfileState> state =
      ValueNotifier(const ProfileState.initial());

  Future<void> load({required int? userId}) async {
    if (userId == null) {
      state.value = const ProfileState.initial();
      return;
    }
    state.value = state.value.copyWith(isLoading: true, clearError: true);
    try {
      final routes = await _routesRepository.getRoutesForUser(userId);
      final history = await _queueService.loadHistory();
      final pending = await _queueService.loadQueue();
      state.value = state.value.copyWith(
        isLoading: false,
        myRoutes: routes,
        history: history,
        pendingUploads: pending.length,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}
