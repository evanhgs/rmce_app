import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/permissions/permission_coordinator.dart';
import '../../services/gps_service.dart';
import '../../services/geo_websocket_service.dart';
import '../auth/auth_controller.dart';
import '../challenges/challenges_controller.dart';
import '../posts/posts_controller.dart';
import 'friends_controller.dart';
import 'friends_models.dart';

class FriendsSocialPage extends StatefulWidget {
  const FriendsSocialPage({
    super.key,
    required this.authController,
    required this.friendsController,
    required this.postsController,
    required this.challengesController,
  });

  final AuthController authController;
  final FriendsController friendsController;
  final PostsController postsController;
  final ChallengesController challengesController;

  @override
  State<FriendsSocialPage> createState() => _FriendsSocialPageState();
}

class _FriendsSocialPageState extends State<FriendsSocialPage> {
  final MapController _mapController = MapController();
  final GPSService _gpsService = GPSService();
  final PermissionCoordinator _permissionCoordinator = PermissionCoordinator();
  final TextEditingController _friendController = TextEditingController();
  final TextEditingController _postTitleController = TextEditingController();
  final TextEditingController _postBodyController = TextEditingController();
  StreamSubscription<SpeedData>? _gpsSubscription;
  LatLng? _currentPosition;
  bool _didCenterOnUser = false;
  String? _gpsMessage;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _gpsSubscription = _gpsService.speedStream.listen((data) {
      _applyGpsData(data, recenterIfNeeded: !_didCenterOnUser);
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
      _applyGpsData(current, recenterIfNeeded: true);
    } else if (mounted) {
      setState(() {
        _gpsMessage =
            'Position introuvable pour l’instant. Vérifie GPS et localisation.';
      });
    }
  }

  void _applyGpsData(
    SpeedData data, {
    required bool recenterIfNeeded,
  }) {
    if (!mounted) {
      return;
    }
    final nextPosition = LatLng(data.latitude, data.longitude);
    setState(() {
      _currentPosition = nextPosition;
      _gpsMessage = null;
    });
    if (recenterIfNeeded) {
      _mapController.move(nextPosition, 15);
      _didCenterOnUser = true;
    }
  }

  Future<void> _centerOnUser() async {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
      return;
    }
    final granted = await _permissionCoordinator.ensureLocationPermissionForMaps();
    if (!mounted) {
      return;
    }
    if (!granted) {
      setState(() {
        _gpsMessage =
            'Impossible de se localiser sans permission de localisation.';
      });
      return;
    }
    await _gpsService.init();
    final current = await _gpsService.refreshCurrentPosition();
    if (current == null) {
      setState(() {
        _gpsMessage =
            'Aucune position disponible. Active le GPS du téléphone puis réessaie.';
      });
      return;
    }
    _applyGpsData(current, recenterIfNeeded: true);
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _friendController.dispose();
    _postTitleController.dispose();
    _postBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: widget.authController.state,
      builder: (context, authState, _) {
        if (!authState.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Connecte-toi pour gérer tes amis, voir leur position et partager tes sessions.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Amis'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Carte'),
                  Tab(text: 'Réseau'),
                  Tab(text: 'Social'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ValueListenableBuilder<FriendsState>(
                  valueListenable: widget.friendsController.state,
                  builder: (context, state, _) => _FriendsMapTab(
                    mapController: _mapController,
                    state: state,
                    currentPosition: _currentPosition,
                    gpsMessage: _gpsMessage,
                    onCenterOnUser: _centerOnUser,
                  ),
                ),
                ValueListenableBuilder<FriendsState>(
                  valueListenable: widget.friendsController.state,
                  builder: (context, state, _) => _FriendsNetworkTab(
                    state: state,
                    friendController: _friendController,
                    onAddFriend: () async {
                      await widget.friendsController
                          .addFriend(_friendController.text.trim());
                      _friendController.clear();
                    },
                    onAccept: widget.friendsController.accept,
                    onReject: widget.friendsController.reject,
                  ),
                ),
                ValueListenableBuilder<PostsState>(
                  valueListenable: widget.postsController.state,
                  builder: (context, postsState, _) {
                    return ValueListenableBuilder<ChallengesState>(
                      valueListenable: widget.challengesController.state,
                      builder: (context, challengeState, _) => _SocialFeedTab(
                        userId: authState.user?['id'] as int,
                        postsState: postsState,
                        challengeState: challengeState,
                        titleController: _postTitleController,
                        bodyController: _postBodyController,
                        onCreatePost: () async {
                          await widget.postsController.create(
                            userId: authState.user?['id'] as int,
                            title: _postTitleController.text.trim(),
                            body: _postBodyController.text.trim(),
                          );
                          _postTitleController.clear();
                          _postBodyController.clear();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FriendsMapTab extends StatelessWidget {
  const _FriendsMapTab({
    required this.mapController,
    required this.state,
    required this.currentPosition,
    required this.gpsMessage,
    required this.onCenterOnUser,
  });

  final MapController mapController;
  final FriendsState state;
  final LatLng? currentPosition;
  final String? gpsMessage;
  final Future<void> Function() onCenterOnUser;

  @override
  Widget build(BuildContext context) {
    final location = state.locations.values.lastOrNull;
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition ??
                (location == null
                    ? const LatLng(48.8566, 2.3522)
                    : LatLng(location.lat, location.lng)),
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'rmce_app.evanhgs.fr',
              subdomains: const ['a', 'b', 'c', 'd'],
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
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: state.locations.entries
                  .map(
                    (entry) => Marker(
                      point: LatLng(entry.value.lat, entry.value.lng),
                      width: 76,
                      height: 54,
                      child: _FriendMarker(
                        location: entry.value,
                        friend: state.friends.firstWhere(
                          (friend) => friend.id == entry.key,
                          orElse: () => FriendModel(
                            id: entry.key,
                            username: 'Ami',
                            email: '',
                            status: 'accepted',
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    state.isSocketConnected ? Icons.wifi : Icons.wifi_off,
                    color: state.isSocketConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.isSocketConnected
                          ? 'Positions temps réel actives.'
                          : 'Connexion live indisponible pour le moment.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'friends_center_btn',
            onPressed: onCenterOnUser,
            child: const Icon(Icons.my_location),
          ),
        ),
        if (gpsMessage != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 86,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  gpsMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendMarker extends StatelessWidget {
  const _FriendMarker({
    required this.location,
    required this.friend,
  });

  final FriendLocation location;
  final FriendModel friend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(friend.username),
        ),
      ],
    );
  }
}

class _FriendsNetworkTab extends StatelessWidget {
  const _FriendsNetworkTab({
    required this.state,
    required this.friendController,
    required this.onAddFriend,
    required this.onAccept,
    required this.onReject,
  });

  final FriendsState state;
  final TextEditingController friendController;
  final Future<void> Function() onAddFriend;
  final Future<void> Function(int friendshipId) onAccept;
  final Future<void> Function(int friendshipId) onReject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inviter un ami', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: friendController,
                  decoration: const InputDecoration(
                    labelText: 'Pseudo de l’ami',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onAddFriend,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Envoyer la demande'),
                ),
                if (state.feedbackMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.feedbackMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Demandes reçues', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...state.pendingRequests.map(
          (request) => Card(
            child: ListTile(
              title: Text(request.username),
              subtitle: Text(request.email),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    onPressed: () => onAccept(request.friendshipId),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  IconButton(
                    onPressed: () => onReject(request.friendshipId),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Mes amis', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...state.friends.map(
          (friend) => Card(
            child: ListTile(
              title: Text(friend.username),
              subtitle: Text(friend.email),
              trailing: const Icon(Icons.people_outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialFeedTab extends StatelessWidget {
  const _SocialFeedTab({
    required this.userId,
    required this.postsState,
    required this.challengeState,
    required this.titleController,
    required this.bodyController,
    required this.onCreatePost,
  });

  final int userId;
  final PostsState postsState;
  final ChallengesState challengeState;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final Future<void> Function() onCreatePost;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partager un ressenti', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onCreatePost,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Publier'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (challengeState.availableChallenges.isNotEmpty) ...[
          Text('Défis ouverts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...challengeState.availableChallenges.take(3).map(
                (challenge) => Card(
                  child: ListTile(
                    title: Text('Défi parcours #${challenge.routeId}'),
                    subtitle: Text('Statut: ${challenge.status}'),
                    trailing: const Icon(Icons.emoji_events_outlined),
                  ),
                ),
              ),
          const SizedBox(height: 16),
        ],
        Text('Publications', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...postsState.posts.map(
          (post) => Card(
            child: ListTile(
              title: Text(post.title),
              subtitle: Text(post.body),
              trailing: post.userId == userId
                  ? const Icon(Icons.person)
                  : const Icon(Icons.public),
            ),
          ),
        ),
      ],
    );
  }
}
