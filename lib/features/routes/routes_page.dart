import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/list_extensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/permissions/permission_coordinator.dart';
import '../../services/gps_service.dart';
import '../auth/auth_controller.dart';
import '../challenges/challenges_controller.dart';
import '../run_session/run_models.dart';
import '../run_session/run_session_controller.dart';
import 'route_composer_controller.dart';
import 'route_explorer_controller.dart';
import 'route_models.dart';

enum RoutesViewMode { explorer, create, live }

class RoutesPage extends StatefulWidget {
  const RoutesPage({
    super.key,
    required this.authController,
    required this.explorerController,
    required this.composerController,
    required this.runSessionController,
    required this.challengesController,
  });

  final AuthController authController;
  final RouteExplorerController explorerController;
  final RouteComposerController composerController;
  final RunSessionController runSessionController;
  final ChallengesController challengesController;

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final MapController _mapController = MapController();
  final GPSService _gpsService = GPSService();
  final PermissionCoordinator _permissionCoordinator = PermissionCoordinator();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _liveNameController =
      TextEditingController(text: 'Parcours libre');
  final TextEditingController _liveDescriptionController =
      TextEditingController();

  StreamSubscription<SpeedData>? _gpsSubscription;
  RoutesViewMode _mode = RoutesViewMode.explorer;
  bool _livePublic = false;
  LatLng? _currentPosition;
  double _currentZoom = 16;
  String? _gpsMessage;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _gpsSubscription = _gpsService.speedStream.listen((data) {
      _applyGpsData(data, keepCentered: true);
    });
  }

  Future<void> _initLocation() async {
    final granted = await _permissionCoordinator.ensureLocationPermissionForMaps();
    if (!mounted) {
      return;
    }
    if (!granted) {
      setState(() {
        _gpsMessage =
            'La localisation n’est pas autorisée. Active-la pour centrer la carte.';
      });
      return;
    }

    await _gpsService.init();
    final current = await _gpsService.refreshCurrentPosition();
    if (current != null) {
      _applyGpsData(current, keepCentered: true);
    } else if (mounted) {
      setState(() {
        _gpsMessage =
            'Position introuvable pour l’instant. Vérifie GPS et localisation.';
      });
    }
  }

  void _applyGpsData(
    SpeedData data, {
    required bool keepCentered,
  }) {
    final nextPosition = LatLng(data.latitude, data.longitude);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPosition = nextPosition;
      _gpsMessage = null;
    });
    if (keepCentered) {
      _mapController.move(nextPosition, _currentZoom);
    }
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _liveNameController.dispose();
    _liveDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: widget.authController.state,
      builder: (context, authState, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Parcours'),
            actions: [
              IconButton(
                onPressed: authState.isLoggedIn
                    ? () => widget.explorerController.load(
                          userId: authState.user?['id'] as int?,
                        )
                    : null,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SegmentedButton<RoutesViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: RoutesViewMode.explorer,
                      icon: Icon(Icons.explore_outlined),
                      label: Text('Explorer'),
                    ),
                    ButtonSegment(
                      value: RoutesViewMode.create,
                      icon: Icon(Icons.draw_outlined),
                      label: Text('Créer'),
                    ),
                    ButtonSegment(
                      value: RoutesViewMode.live,
                      icon: Icon(Icons.track_changes_outlined),
                      label: Text('En direct'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
              ),
              Expanded(
                child: switch (_mode) {
                  RoutesViewMode.explorer => _ExplorerView(
                      authState: authState,
                      mapController: _mapController,
                      explorerController: widget.explorerController,
                      runSessionController: widget.runSessionController,
                      challengesController: widget.challengesController,
                      currentPosition: _currentPosition,
                      gpsMessage: _gpsMessage,
                      onMapPositionChanged: _handleMapPositionChanged,
                    ),
                  RoutesViewMode.create => _CreateView(
                      mapController: _mapController,
                      controller: widget.composerController,
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      currentPosition: _currentPosition,
                      gpsMessage: _gpsMessage,
                      onMapPositionChanged: _handleMapPositionChanged,
                      onRouteSaved: () => widget.explorerController.load(
                        userId: authState.user?['id'] as int?,
                      ),
                    ),
                  RoutesViewMode.live => _LiveView(
                      controller: widget.runSessionController,
                      mapController: _mapController,
                      liveNameController: _liveNameController,
                      liveDescriptionController: _liveDescriptionController,
                      livePublic: _livePublic,
                      currentPosition: _currentPosition,
                      gpsMessage: _gpsMessage,
                      onMapPositionChanged: _handleMapPositionChanged,
                      onVisibilityChanged: (value) {
                        setState(() => _livePublic = value);
                      },
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMapPositionChanged(MapCamera camera, bool hasGesture) {
    _currentZoom = camera.zoom;
    if (hasGesture && _currentPosition != null) {
      _mapController.move(_currentPosition!, _currentZoom);
    }
  }
}

class _ExplorerView extends StatelessWidget {
  const _ExplorerView({
    required this.authState,
    required this.mapController,
    required this.explorerController,
    required this.runSessionController,
    required this.challengesController,
    required this.currentPosition,
    required this.gpsMessage,
    required this.onMapPositionChanged,
  });

  final AuthState authState;
  final MapController mapController;
  final RouteExplorerController explorerController;
  final RunSessionController runSessionController;
  final ChallengesController challengesController;
  final LatLng? currentPosition;
  final String? gpsMessage;
  final void Function(MapCamera camera, bool hasGesture) onMapPositionChanged;

  @override
  Widget build(BuildContext context) {
    if (!authState.isLoggedIn) {
      return const _CenteredInfo(
        title: 'Connexion requise',
        subtitle: 'Connecte-toi pour explorer, enregistrer et lancer des parcours.',
      );
    }

    return ValueListenableBuilder<RouteExplorerState>(
      valueListenable: explorerController.state,
      builder: (context, state, _) {
        final route = state.selectedRoute;
        final polylines = route == null
            ? const <Polyline>[]
            : [
                Polyline(
                  points: route.polyline,
                  strokeWidth: 5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: route?.polyline.firstOrNull ??
                            currentPosition ??
                            const LatLng(48.8566, 2.3522),
                        initialZoom: route == null ? 12 : 15,
                        onPositionChanged: onMapPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'rmce_app.evanhgs.fr',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        if (polylines.isNotEmpty)
                          PolylineLayer(polylines: polylines),
                        if (currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPosition!,
                                width: 18,
                                height: 18,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (route != null)
                          MarkerLayer(
                            markers: route.polyline
                                .map(
                                  (point) => Marker(
                                    point: point,
                                    width: 12,
                                    height: 12,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (gpsMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                gpsMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            if (route != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(route.description.isEmpty
                          ? 'Aucune description'
                          : route.description),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(formatDistance(route.distanceMeters))),
                          Chip(label: Text(route.isPublic ? 'Public' : 'Privé')),
                          Chip(label: Text('${route.points.length} points')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => runSessionController.startForRoute(route),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Lancer'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => challengesController.createChallenge(
                              routeId: route.id,
                            ),
                            icon: const Icon(Icons.emoji_events_outlined),
                            label: const Text('Défi ouvert'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Mes parcours', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...state.myRoutes.map(
              (item) => _RouteTile(
                route: item,
                onTap: () => explorerController.selectRoute(item),
              ),
            ),
            const SizedBox(height: 16),
            Text('Parcours publics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...state.publicRoutes.map(
              (item) => _RouteTile(
                route: item,
                onTap: () => explorerController.selectRoute(item),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CreateView extends StatelessWidget {
  const _CreateView({
    required this.mapController,
    required this.controller,
    required this.nameController,
    required this.descriptionController,
    required this.currentPosition,
    required this.gpsMessage,
    required this.onMapPositionChanged,
    required this.onRouteSaved,
  });

  final MapController mapController;
  final RouteComposerController controller;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final LatLng? currentPosition;
  final String? gpsMessage;
  final void Function(MapCamera camera, bool hasGesture) onMapPositionChanged;
  final VoidCallback onRouteSaved;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RouteComposerState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: state.points.lastOrNull?.latLng ??
                            currentPosition ??
                            const LatLng(48.8566, 2.3522),
                        initialZoom: 14,
                        onPositionChanged: onMapPositionChanged,
                        onLongPress: (_, latLng) {
                          controller.addPoint(
                            RoutePathPoint(
                              latitude: latLng.latitude,
                              longitude: latLng.longitude,
                            ),
                          );
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'rmce_app.evanhgs.fr',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        if (state.points.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points:
                                    state.points.map((point) => point.latLng).toList(),
                                strokeWidth: 5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: state.points
                              .map(
                                (point) => Marker(
                                  point: point.latLng,
                                  width: 18,
                                  height: 18,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      border:
                                          Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        if (currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPosition!,
                                width: 18,
                                height: 18,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    border:
                                        Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (gpsMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                gpsMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      onChanged: controller.updateName,
                      decoration:
                          const InputDecoration(labelText: 'Nom du parcours'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      onChanged: controller.updateDescription,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: state.isPublic,
                      onChanged: controller.updateVisibility,
                      title: const Text('Parcours public'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (state.errorMessage != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (state.feedbackMessage != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.feedbackMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: controller.addCurrentPosition,
                          icon: const Icon(Icons.my_location_outlined),
                          label: const Text('Ajouter ma position'),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.clear,
                          icon: const Icon(Icons.layers_clear_outlined),
                          label: const Text('Effacer'),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final route = await controller.save();
                            if (route != null) {
                              onRouteSaved();
                              nameController.clear();
                              descriptionController.clear();
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveView extends StatelessWidget {
  const _LiveView({
    required this.controller,
    required this.mapController,
    required this.liveNameController,
    required this.liveDescriptionController,
    required this.livePublic,
    required this.currentPosition,
    required this.gpsMessage,
    required this.onMapPositionChanged,
    required this.onVisibilityChanged,
  });

  final RunSessionController controller;
  final MapController mapController;
  final TextEditingController liveNameController;
  final TextEditingController liveDescriptionController;
  final bool livePublic;
  final LatLng? currentPosition;
  final String? gpsMessage;
  final void Function(MapCamera camera, bool hasGesture) onMapPositionChanged;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RunSessionState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: state.path.lastOrNull?.latLng ??
                            currentPosition ??
                            const LatLng(48.8566, 2.3522),
                        initialZoom: 14,
                        onPositionChanged: onMapPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'rmce_app.evanhgs.fr',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        if (state.path.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points:
                                    state.path.map((point) => point.latLng).toList(),
                                strokeWidth: 6,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        if (currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPosition!,
                                width: 18,
                                height: 18,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    border:
                                        Border.all(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (gpsMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                gpsMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session libre', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: liveNameController,
                      decoration:
                          const InputDecoration(labelText: 'Nom du parcours généré'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: liveDescriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: livePublic,
                      onChanged: onVisibilityChanged,
                      title: const Text('Rendre le parcours public après enregistrement'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${formatDuration(state.elapsed)} • ${formatDistance(state.metrics.distanceMeters)} • ${formatSpeed(state.metrics.currentSpeedKmh)}',
                    ),
                    const SizedBox(height: 16),
                    if (state.phase == RunSessionPhase.idle ||
                        state.phase == RunSessionPhase.completed ||
                        state.phase == RunSessionPhase.error)
                      FilledButton.icon(
                        onPressed: () {
                          controller.startFreeRun(
                            RouteDraft(
                              name: liveNameController.text.trim().isEmpty
                                  ? 'Parcours libre'
                                  : liveNameController.text.trim(),
                              description: liveDescriptionController.text.trim(),
                              isPublic: livePublic,
                              points: const [],
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Démarrer'),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: state.phase == RunSessionPhase.running
                                ? controller.pause
                                : null,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: state.phase == RunSessionPhase.paused
                                ? controller.resume
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Reprendre'),
                          ),
                          FilledButton.icon(
                            onPressed: controller.finish,
                            icon: const Icon(Icons.flag),
                            label: const Text('Arrêter'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.route,
    required this.onTap,
  });

  final RouteModel route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(route.name),
        subtitle: Text(
          '${formatDistance(route.distanceMeters)} • ${route.isPublic ? 'Public' : 'Privé'}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CenteredInfo extends StatelessWidget {
  const _CenteredInfo({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
