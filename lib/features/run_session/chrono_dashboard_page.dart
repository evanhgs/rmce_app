import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'run_models.dart';
import 'run_session_controller.dart';

class ChronoDashboardPage extends StatelessWidget {
  const ChronoDashboardPage({
    super.key,
    required this.controller,
    required this.onOpenRoutes,
  });

  final RunSessionController controller;
  final VoidCallback onOpenRoutes;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RunSessionState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chrono'),
            actions: [
              IconButton(
                onPressed: controller.retryPendingUploads,
                icon: Badge.count(
                  count: state.pendingUploads,
                  isLabelVisible: state.pendingUploads > 0,
                  child: const Icon(Icons.sync),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HeroSessionCard(
                state: state,
                onOpenRoutes: onOpenRoutes,
                onPause: controller.pause,
                onResume: controller.resume,
                onFinish: controller.finish,
              ),
              const SizedBox(height: 16),
              _MetricsGrid(state: state),
              const SizedBox(height: 16),
              _StatusCard(state: state),
              if (state.lastSummary != null) ...[
                const SizedBox(height: 16),
                _LastSummaryCard(summary: state.lastSummary!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroSessionCard extends StatelessWidget {
  const _HeroSessionCard({
    required this.state,
    required this.onOpenRoutes,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final RunSessionState state;
  final VoidCallback onOpenRoutes;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.route?.name ??
                  state.routeDraft?.name ??
                  'Prêt pour une session mesurée',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.phase == RunSessionPhase.idle
                  ? 'Démarre un parcours depuis l’onglet Parcours pour lancer le suivi GPS et capteurs.'
                  : 'Session ${state.freeMode ? 'libre' : 'sur parcours'} en cours avec mesures temps réel.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              formatDuration(state.elapsed),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatSpeed(state.metrics.currentSpeedKmh),
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.phase == RunSessionPhase.running ? onPause : null,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Pause'),
                ),
                FilledButton.tonalIcon(
                  onPressed: state.phase == RunSessionPhase.paused ? onResume : null,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Reprendre'),
                ),
                FilledButton.icon(
                  onPressed: state.phase == RunSessionPhase.running ||
                          state.phase == RunSessionPhase.paused
                      ? onFinish
                      : null,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Terminer'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenRoutes,
                  icon: const Icon(Icons.route_outlined),
                  label: Text(
                    state.phase == RunSessionPhase.idle
                        ? 'Choisir un parcours'
                        : 'Voir les parcours',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.state});

  final RunSessionState state;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Distance', formatDistance(state.metrics.distanceMeters)),
      ('Vitesse max', formatSpeed(state.metrics.maxSpeedKmh)),
      ('Vitesse moy.', formatSpeed(state.metrics.avgSpeedKmh)),
      ('Précision GPS', '${state.metrics.accuracyMeters.toStringAsFixed(1)} m'),
      ('G max', state.metrics.maxGForce.toStringAsFixed(2)),
      (
        'Inclinaison',
        '${state.metrics.maxInclinationDegrees.toStringAsFixed(1)}°',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final (label, value) = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF172033),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final RunSessionState state;

  @override
  Widget build(BuildContext context) {
    final qualityColor = switch (state.metrics.gpsQuality) {
      GpsQuality.excellent => Colors.green,
      GpsQuality.good => Colors.lightGreen,
      GpsQuality.degraded => Colors.orange,
      GpsQuality.poor => Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('État de session', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.gps_fixed, color: qualityColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Qualité GPS: ${state.metrics.gpsQuality.name}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.sensors),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${state.samplesCollected} échantillons capteurs collectés',
                  ),
                ),
              ],
            ),
            if (state.pendingUploads > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${state.pendingUploads} envoi(s) en attente de reprise.',
                    ),
                  ),
                ],
              ),
            ],
            if (state.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                state.lastError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LastSummaryCard extends StatelessWidget {
  const _LastSummaryCard({required this.summary});

  final RunSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dernière session', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(summary.routeName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(formatDateTime(summary.completedAt)),
            const SizedBox(height: 16),
            Text(
              '${formatDuration(summary.elapsed)} • ${formatDistance(summary.metrics.distanceMeters)} • ${formatSpeed(summary.metrics.maxSpeedKmh)}',
            ),
          ],
        ),
      ),
    );
  }
}
