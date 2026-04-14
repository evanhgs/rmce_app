import 'package:flutter/foundation.dart';

import '../../services/gps_service.dart';
import 'route_models.dart';
import 'routes_repository.dart';

class RouteComposerState {
  const RouteComposerState({
    required this.name,
    required this.description,
    required this.isPublic,
    required this.points,
    required this.isSaving,
    this.feedbackMessage,
    this.errorMessage,
  });

  final String name;
  final String description;
  final bool isPublic;
  final List<RoutePathPoint> points;
  final bool isSaving;
  final String? feedbackMessage;
  final String? errorMessage;

  const RouteComposerState.initial()
      : name = '',
        description = '',
        isPublic = false,
        points = const [],
        isSaving = false,
        feedbackMessage = null,
        errorMessage = null;

  RouteComposerState copyWith({
    String? name,
    String? description,
    bool? isPublic,
    List<RoutePathPoint>? points,
    bool? isSaving,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return RouteComposerState(
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      points: points ?? this.points,
      isSaving: isSaving ?? this.isSaving,
      feedbackMessage:
          clearFeedback ? null : feedbackMessage ?? this.feedbackMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  RouteDraft get draft => RouteDraft(
        name: name.trim().isEmpty ? 'Parcours libre' : name.trim(),
        description: description.trim(),
        isPublic: isPublic,
        points: points,
      );
}

class RouteComposerController {
  RouteComposerController({
    required RoutesRepository repository,
    GPSService? gpsService,
  })  : _repository = repository,
        _gpsService = gpsService ?? GPSService();

  final RoutesRepository _repository;
  final GPSService _gpsService;

  final ValueNotifier<RouteComposerState> state =
      ValueNotifier(const RouteComposerState.initial());

  void updateName(String value) {
    state.value = state.value.copyWith(name: value, clearError: true);
  }

  void updateDescription(String value) {
    state.value = state.value.copyWith(description: value);
  }

  void updateVisibility(bool value) {
    state.value = state.value.copyWith(isPublic: value);
  }

  void addPoint(RoutePathPoint point) {
    final updated = [...state.value.points, point];
    state.value = state.value.copyWith(
      points: updated,
      clearError: true,
      clearFeedback: true,
    );
  }

  void addCurrentPosition() {
    addPoint(
      RoutePathPoint(
        latitude: _gpsService.latitude,
        longitude: _gpsService.longitude,
      ),
    );
  }

  void clear() {
    state.value = const RouteComposerState.initial();
  }

  Future<RouteModel?> save() async {
    if (state.value.points.length < 2) {
      state.value = state.value.copyWith(
        errorMessage: 'Ajoute au moins deux points pour enregistrer un parcours.',
      );
      return null;
    }

    state.value = state.value.copyWith(
      isSaving: true,
      clearError: true,
      clearFeedback: true,
    );
    try {
      final route = await _repository.createRoute(state.value.draft);
      state.value = const RouteComposerState.initial().copyWith(
        feedbackMessage: 'Parcours enregistré avec succès.',
      );
      return route;
    } catch (error) {
      state.value = state.value.copyWith(
        isSaving: false,
        errorMessage: error.toString(),
      );
      return null;
    }
  }
}
