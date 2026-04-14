import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../routes/routes_repository.dart';
import 'run_models.dart';
import 'scores_repository.dart';

class RunUploadQueueService {
  RunUploadQueueService({
    required RoutesRepository routesRepository,
    required ScoresRepository scoresRepository,
  })  : _routesRepository = routesRepository,
        _scoresRepository = scoresRepository;

  static const _queueKey = 'run_upload_queue';
  static const _historyKey = 'run_history';

  final RoutesRepository _routesRepository;
  final ScoresRepository _scoresRepository;

  Future<List<PendingRunUpload>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final rawQueue = prefs.getStringList(_queueKey) ?? const [];
    return rawQueue
        .map(PendingRunUpload.decode)
        .toList(growable: false);
  }

  Future<void> enqueue(PendingRunUpload upload) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await loadQueue();
    final updated = [...queue, upload];
    await prefs.setStringList(
      _queueKey,
      updated.map((item) => item.encode()).toList(growable: false),
    );
  }

  Future<void> saveSummary(RunSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_historyKey) ?? const [];
    final updated = [
      jsonEncode(summary.toJson()),
      ...entries,
    ].take(12).toList(growable: false);
    await prefs.setStringList(_historyKey, updated);
  }

  Future<List<RunSummary>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_historyKey) ?? const [];
    return rawItems
        .map((raw) => RunSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<int> retryPendingUploads() async {
    final queue = await loadQueue();
    if (queue.isEmpty) {
      return 0;
    }

    final remaining = <PendingRunUpload>[];
    for (final upload in queue) {
      try {
        var routeId = upload.routeId;
        if (routeId == null && upload.routeDraft != null) {
          final route = await _routesRepository.createRoute(
            upload.routeDraft!,
            points: upload.recordedPath,
            distanceMeters: upload.metrics.distanceMeters,
          );
          routeId = route.id;
        }

        if (routeId == null) {
          remaining.add(upload);
          continue;
        }

        final score = await _scoresRepository.submitScore(
          routeId: routeId,
          elapsed: upload.elapsed,
          metrics: upload.metrics,
        );
        await _scoresRepository.uploadSensorDataBulk(
          scoreId: score.id,
          samples: upload.samples,
        );
      } catch (_) {
        remaining.add(upload);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queueKey,
      remaining.map((item) => item.encode()).toList(growable: false),
    );
    return remaining.length;
  }
}
