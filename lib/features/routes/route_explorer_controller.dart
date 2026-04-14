import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/list_extensions.dart';
import 'route_models.dart';
import 'routes_repository.dart';

class RouteExplorerState {
  const RouteExplorerState({
    required this.isLoading,
    required this.publicRoutes,
    required this.myRoutes,
    this.selectedRoute,
    this.errorMessage,
  });

  final bool isLoading;
  final List<RouteModel> publicRoutes;
  final List<RouteModel> myRoutes;
  final RouteModel? selectedRoute;
  final String? errorMessage;

  const RouteExplorerState.initial()
      : isLoading = false,
        publicRoutes = const [],
        myRoutes = const [],
        selectedRoute = null,
        errorMessage = null;

  RouteExplorerState copyWith({
    bool? isLoading,
    List<RouteModel>? publicRoutes,
    List<RouteModel>? myRoutes,
    RouteModel? selectedRoute,
    String? errorMessage,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return RouteExplorerState(
      isLoading: isLoading ?? this.isLoading,
      publicRoutes: publicRoutes ?? this.publicRoutes,
      myRoutes: myRoutes ?? this.myRoutes,
      selectedRoute: clearSelected ? null : selectedRoute ?? this.selectedRoute,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RouteExplorerController {
  RouteExplorerController({
    required RoutesRepository repository,
  }) : _repository = repository;

  final RoutesRepository _repository;
  final ValueNotifier<RouteExplorerState> state =
      ValueNotifier(const RouteExplorerState.initial());

  Future<void> load({int? userId}) async {
    state.value = state.value.copyWith(isLoading: true, clearError: true);
    try {
      final publicRoutes = await _repository.getPublicRoutes();
      final myRoutes = userId == null
          ? <RouteModel>[]
          : await _repository.getRoutesForUser(userId);
      final selected = state.value.selectedRoute ??
          (myRoutes.isNotEmpty ? myRoutes.first : publicRoutes.firstOrNull);

      state.value = state.value.copyWith(
        isLoading: false,
        publicRoutes: publicRoutes,
        myRoutes: myRoutes,
        selectedRoute: selected,
      );
    } on ApiException catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    }
  }

  void selectRoute(RouteModel route) {
    state.value = state.value.copyWith(selectedRoute: route);
  }
}
