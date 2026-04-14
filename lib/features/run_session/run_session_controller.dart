import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/permissions/permission_coordinator.dart';
import '../../services/gps_service.dart';
import '../routes/route_models.dart';
import '../routes/routes_repository.dart';
import 'run_models.dart';
import 'run_tracking_service.dart';
import 'run_upload_queue_service.dart';
import 'scores_repository.dart';
import 'sensor_capture_service.dart';

class RunSessionController {
  RunSessionController({
    required PermissionCoordinator permissionCoordinator,
    required RoutesRepository routesRepository,
    required ScoresRepository scoresRepository,
    required RunUploadQueueService queueService,
    GPSService? gpsService,
    RunTrackingService? trackingService,
    SensorCaptureService? sensorCaptureService,
  })  : _permissionCoordinator = permissionCoordinator,
        _routesRepository = routesRepository,
        _scoresRepository = scoresRepository,
        _queueService = queueService,
        _gpsService = gpsService ?? GPSService(),
        _trackingService = trackingService ?? RunTrackingService(),
        _sensorCaptureService = sensorCaptureService ?? SensorCaptureService();

  final PermissionCoordinator _permissionCoordinator;
  final RoutesRepository _routesRepository;
  final ScoresRepository _scoresRepository;
  final RunUploadQueueService _queueService;
  final GPSService _gpsService;
  final RunTrackingService _trackingService;
  final SensorCaptureService _sensorCaptureService;

  final ValueNotifier<RunSessionState> state =
      ValueNotifier(const RunSessionState.initial());

  StreamSubscription<SpeedData>? _gpsSubscription;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pausedAt;

  Future<void> initialize() async {
    final history = await _queueService.loadHistory();
    final pending = await _queueService.loadQueue();
    if (history.isNotEmpty || pending.isNotEmpty) {
      state.value = state.value.copyWith(
        lastSummary: history.isEmpty ? null : history.first,
        pendingUploads: pending.length,
      );
    }
  }

  Future<PermissionStatusSummary> requestPermissions() {
    return _permissionCoordinator.requestRunPermissions();
  }

  Future<void> startForRoute(RouteModel route) async {
    await _startSession(route: route, freeMode: false);
  }

  Future<void> startFreeRun(RouteDraft draft) async {
    await _startSession(routeDraft: draft, freeMode: true);
  }

  Future<void> _startSession({
    RouteModel? route,
    RouteDraft? routeDraft,
    required bool freeMode,
  }) async {
    final permissions = await _permissionCoordinator.requestRunPermissions();
    if (!permissions.canStartTrackedRun) {
      state.value = state.value.copyWith(
        phase: RunSessionPhase.error,
        lastError:
            'Les permissions localisation et mouvement sont nécessaires.',
      );
      return;
    }

    await _gpsService.init();
    _trackingService.reset();
    _sensorCaptureService.reset();
    await _sensorCaptureService.start(_gpsService.speedStream);

    _startedAt = DateTime.now();
    _pausedTotal = Duration.zero;
    _pausedAt = null;

    await _gpsSubscription?.cancel();
    _gpsSubscription = _gpsService.speedStream.listen((data) {
      if (state.value.phase != RunSessionPhase.running) {
        return;
      }
      final elapsed = _currentElapsed();
      final gpsSnapshot = _trackingService.applyGpsSample(data, elapsed);
      _sensorCaptureService.attachGpsSample(data);
      final sensorSnapshot = _sensorCaptureService.snapshot;
      final merged = _trackingService.applySensorStats(
        gForce: sensorSnapshot.maxGForce,
        inclinationDegrees: sensorSnapshot.maxInclinationDegrees,
        soundDb: sensorSnapshot.maxSoundDb,
      );
      state.value = state.value.copyWith(
        elapsed: elapsed,
        metrics: merged.metrics.copyWith(
          distanceMeters: gpsSnapshot.metrics.distanceMeters,
        ),
        path: merged.path,
        samplesCollected: sensorSnapshot.samples.length,
        phase: RunSessionPhase.running,
        route: route,
        routeDraft: routeDraft,
        freeMode: freeMode,
        clearError: true,
      );
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (state.value.phase == RunSessionPhase.running) {
        state.value = state.value.copyWith(elapsed: _currentElapsed());
      }
    });

    state.value = RunSessionState(
      phase: RunSessionPhase.running,
      elapsed: Duration.zero,
      metrics: const RunMetrics.initial(),
      path: const [],
      samplesCollected: 0,
      freeMode: freeMode,
      route: route,
      routeDraft: routeDraft,
      pendingUploads: state.value.pendingUploads,
      lastSummary: state.value.lastSummary,
      lastScore: state.value.lastScore,
    );
  }

  void pause() {
    if (state.value.phase != RunSessionPhase.running) {
      return;
    }
    _pausedAt = DateTime.now();
    state.value = state.value.copyWith(phase: RunSessionPhase.paused);
  }

  void resume() {
    if (state.value.phase != RunSessionPhase.paused || _pausedAt == null) {
      return;
    }
    _pausedTotal += DateTime.now().difference(_pausedAt!);
    _pausedAt = null;
    state.value = state.value.copyWith(phase: RunSessionPhase.running);
  }

  Future<void> finish() async {
    if (state.value.phase != RunSessionPhase.running &&
        state.value.phase != RunSessionPhase.paused) {
      return;
    }

    state.value = state.value.copyWith(phase: RunSessionPhase.saving);
    _ticker?.cancel();
    await _gpsSubscription?.cancel();
    await _sensorCaptureService.stop();

    final currentState = state.value;
    final pending = PendingRunUpload(
      routeId: currentState.route?.id,
      routeDraft: currentState.routeDraft,
      recordedPath: currentState.path,
      elapsed: currentState.elapsed,
      metrics: currentState.metrics,
      samples: _sensorCaptureService.snapshot.samples,
      createdAt: DateTime.now(),
    );

    ScoreModel? score;
    RouteModel? savedRoute = currentState.route;
    try {
      if (savedRoute == null && currentState.routeDraft != null) {
        savedRoute = await _routesRepository.createRoute(
          currentState.routeDraft!,
          points: currentState.path,
          distanceMeters: currentState.metrics.distanceMeters,
        );
      }

      if (savedRoute != null) {
        score = await _scoresRepository.submitScore(
          routeId: savedRoute.id,
          elapsed: currentState.elapsed,
          metrics: currentState.metrics,
        );
        await _scoresRepository.uploadSensorDataBulk(
          scoreId: score.id,
          samples: _sensorCaptureService.snapshot.samples,
        );
      } else {
        await _queueService.enqueue(pending);
      }
    } catch (_) {
      await _queueService.enqueue(pending);
    }

    final summary = RunSummary(
      routeName: savedRoute?.name ??
          currentState.routeDraft?.name ??
          currentState.route?.name ??
          'Session libre',
      routeId: savedRoute?.id ?? currentState.route?.id,
      freeMode: currentState.freeMode,
      elapsed: currentState.elapsed,
      metrics: currentState.metrics,
      completedAt: DateTime.now(),
    );
    await _queueService.saveSummary(summary);
    final pendingCount = await _queueService.retryPendingUploads();

    state.value = RunSessionState(
      phase: RunSessionPhase.completed,
      elapsed: currentState.elapsed,
      metrics: currentState.metrics,
      path: currentState.path,
      samplesCollected: _sensorCaptureService.snapshot.samples.length,
      freeMode: currentState.freeMode,
      route: savedRoute,
      routeDraft: currentState.routeDraft,
      lastSummary: summary,
      pendingUploads: pendingCount,
      lastScore: score,
    );
  }

  Future<void> retryPendingUploads() async {
    final pendingCount = await _queueService.retryPendingUploads();
    state.value = state.value.copyWith(pendingUploads: pendingCount);
  }

  void resetSessionView() {
    state.value = RunSessionState(
      phase: RunSessionPhase.idle,
      elapsed: Duration.zero,
      metrics: const RunMetrics.initial(),
      path: const [],
      samplesCollected: 0,
      freeMode: false,
      lastSummary: state.value.lastSummary,
      pendingUploads: state.value.pendingUploads,
    );
  }

  Duration _currentElapsed() {
    final startedAt = _startedAt;
    if (startedAt == null) {
      return Duration.zero;
    }
    final reference = _pausedAt ?? DateTime.now();
    return reference.difference(startedAt) - _pausedTotal;
  }

  void dispose() {
    _ticker?.cancel();
    _gpsSubscription?.cancel();
    _sensorCaptureService.stop();
    state.dispose();
  }
}
