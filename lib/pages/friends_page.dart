import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../services/geo_websocket_service.dart';
import '../services/gps_service.dart';

class FriendsPage extends StatefulWidget {
  final String title;
  const FriendsPage({super.key, required this.title});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _auth = AuthService();
  final _friendsService = FriendsService();
  final _geoService = GeoWebSocketService();
  final _gpsService = GPSService();
  final _mapController = MapController();

  late final TabController _tabController;

  bool _isLoggedIn = false;
  bool _wsConnected = false;

  List<FriendInfo> _friends = [];
  List<PendingRequest> _pendingRequests = [];
  final Map<int, FriendLocation> _friendLocations = {};

  LatLng? _myPosition;
  StreamSubscription<SpeedData>? _gpsSub;
  StreamSubscription<FriendLocation>? _wsSub;
  StreamSubscription<bool>? _wsStatusSub;
  Timer? _locationTimer;

  final _addController = TextEditingController();
  bool _isAdding = false;
  String? _addError;
  String? _addSuccess;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoggedIn) {
      _geoService.reconnect().then((_) => _loadFriends());
    }
  }

  Future<void> _init() async {
    final loggedIn = await _auth.isLoggedIn();
    if (!mounted) return;
    setState(() => _isLoggedIn = loggedIn);
    if (!loggedIn) return;

    _gpsService.init();
    _gpsSub = _gpsService.speedStream.listen((data) {
      if (mounted) {
        setState(() => _myPosition = LatLng(data.latitude, data.longitude));
      }
    });

    await _geoService.connect();

    _wsStatusSub = _geoService.connectionStream.listen((connected) {
      if (mounted) setState(() => _wsConnected = connected);
    });
    if (mounted) setState(() => _wsConnected = _geoService.isConnected);

    _wsSub = _geoService.locationStream.listen((loc) {
      if (mounted) setState(() => _friendLocations[loc.userId] = loc);
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_myPosition != null) {
        _geoService.sendLocation(_myPosition!.latitude, _myPosition!.longitude);
      }
    });

    await _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await _friendsService.getFriends();
    final pending = await _friendsService.getPendingRequests();
    if (mounted) {
      setState(() {
        _friends = friends;
        _pendingRequests = pending;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _gpsSub?.cancel();
    _wsSub?.cancel();
    _wsStatusSub?.cancel();
    _locationTimer?.cancel();
    _addController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _centerOnMe() {
    if (_myPosition != null) _mapController.move(_myPosition!, 15.0);
  }

  Color _colorFor(int userId) {
    const palette = [
      Color(0xFFFF6B6B), // coral
      Color(0xFFFFB347), // orange
      Color(0xFF6BCB77), // green
      Color(0xFF4D96FF), // blue
      Color(0xFFFF6BFF), // pink
      Color(0xFF00D4FF), // cyan
      Color(0xFFFFD93D), // yellow
      Color(0xFFB47FFF), // purple
    ];
    return palette[userId % palette.length];
  }

  String _initials(String username) {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  bool _isOnline(FriendLocation? loc) {
    if (loc == null) return false;
    final ageMs = DateTime.now().millisecondsSinceEpoch - loc.timestamp * 1000;
    return ageMs < 35000;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return _buildNotLoggedIn();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopOverlay(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  // ─── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    final markers = _friendLocations.entries.map((entry) {
      final loc = entry.value;
      final friend = _friends.firstWhere(
        (f) => f.id == loc.userId,
        orElse: () => FriendInfo(
          id: loc.userId,
          username: '?',
          email: '',
          status: 'accepted',
        ),
      );
      return Marker(
        point: LatLng(loc.lat, loc.lng),
        width: 64,
        height: 72,
        child: _buildFriendMarker(friend, loc),
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _myPosition ?? const LatLng(48.8566, 2.3522),
        initialZoom: 14.0,
        minZoom: 3.0,
        maxZoom: 19.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'rmce_app.evanhgs.fr',
          subdomains: const ['a', 'b', 'c', 'd'],
          maxZoom: 19,
          additionalOptions: const {
            'attribution':
                '&copy; OpenStreetMap contributors &copy; CARTO',
          },
        ),
        if (_myPosition != null)
          MarkerLayer(markers: [
            Marker(
              point: _myPosition!,
              width: 22,
              height: 22,
              child: _buildMyMarker(),
            ),
          ]),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildMyMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade500,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade400.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendMarker(FriendInfo friend, FriendLocation loc) {
    final color = _colorFor(friend.id);
    final online = _isOnline(loc);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.9),
                border: Border.all(
                  color: online ? Colors.greenAccent : Colors.grey.shade600,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials(friend.username),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            if (online)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            friend.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top overlay ────────────────────────────────────────────────────────────

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text(
              'AMIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            _wsStatusBadge(),
            const SizedBox(width: 8),
            _iconBtn(Icons.my_location, onTap: _centerOnMe),
          ],
        ),
      ),
    );
  }

  Widget _wsStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _wsConnected
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.red.shade400.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _wsConnected ? Colors.greenAccent : Colors.red.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _wsConnected ? 'EN LIGNE' : 'HORS LIGNE',
            style: TextStyle(
              fontSize: 10,
              color: _wsConnected ? Colors.greenAccent : Colors.red.shade400,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.75),
          border: Border.all(color: Colors.grey.shade700, width: 1),
        ),
        child: Icon(icon, color: Colors.blue.shade400, size: 19),
      ),
    );
  }

  // ─── Bottom sheet ────────────────────────────────────────────────────────────

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize: 0.10,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111116),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: Colors.grey.shade800, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_friends.length} AMI${_friends.length > 1 ? 'S' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    if (_pendingRequests.isNotEmpty)
                      _pendingBadge(_pendingRequests.length),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue.shade400,
                indicatorWeight: 2,
                labelColor: Colors.blue.shade400,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'AMIS'),
                  Tab(text: 'DEMANDES'),
                  Tab(text: 'AJOUTER'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsList(scrollController),
                    _buildPendingList(scrollController),
                    _buildAddFriend(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pendingBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.shade700.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.orange.shade700.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '$count demande${count > 1 ? 's' : ''}',
        style:
            TextStyle(color: Colors.orange.shade400, fontSize: 11),
      ),
    );
  }

  // ─── Tab: Amis ──────────────────────────────────────────────────────────────

  Widget _buildFriendsList(ScrollController scrollController) {
    if (_friends.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline,
        label: 'Aucun ami pour l\'instant',
        sub: 'Utilise l\'onglet AJOUTER pour inviter quelqu\'un',
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _friends.length,
      itemBuilder: (ctx, i) => _friendTile(_friends[i]),
    );
  }

  Widget _friendTile(FriendInfo friend) {
    final loc = _friendLocations[friend.id];
    final online = _isOnline(loc);
    final color = _colorFor(friend.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.8),
                  border: Border.all(
                    color: online
                        ? Colors.greenAccent.withValues(alpha: 0.8)
                        : Colors.grey.shade700,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(friend.username),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              if (online)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  online ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: online
                        ? Colors.greenAccent
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          if (loc != null)
            GestureDetector(
              onTap: () =>
                  _mapController.move(LatLng(loc.lat, loc.lng), 16.0),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade700.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.blue.shade700.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.location_on_outlined,
                    color: Colors.blue.shade400, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Tab: Demandes ──────────────────────────────────────────────────────────

  Widget _buildPendingList(ScrollController scrollController) {
    if (_pendingRequests.isEmpty) {
      return _emptyState(
        icon: Icons.notifications_none,
        label: 'Aucune demande en attente',
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _pendingRequests.length,
      itemBuilder: (ctx, i) => _pendingTile(_pendingRequests[i]),
    );
  }

  Widget _pendingTile(PendingRequest req) {
    final color = _colorFor(req.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.8),
            ),
            child: Center(
              child: Text(
                _initials(req.username),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              req.username,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 15),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await _friendsService.acceptFriend(req.friendshipId);
              await _loadFriends();
              await _geoService.reconnect();
            },
            child: _actionCircle(
                Icons.check, Colors.green.shade400, Colors.green.shade700),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await _friendsService.rejectFriend(req.friendshipId);
              await _loadFriends();
            },
            child: _actionCircle(
                Icons.close, Colors.red.shade400, Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Widget _actionCircle(IconData icon, Color iconColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderColor.withValues(alpha: 0.12),
        border: Border.all(color: borderColor.withValues(alpha: 0.45), width: 1),
      ),
      child: Icon(icon, color: iconColor, size: 19),
    );
  }

  // ─── Tab: Ajouter ───────────────────────────────────────────────────────────

  Widget _buildAddFriend(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECHERCHER PAR PSEUDO',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.shade700, width: 1),
                  ),
                  child: TextField(
                    controller: _addController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Pseudo',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey.shade600, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) =>
                        _isAdding ? null : _submitAddFriend(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isAdding ? null : _submitAddFriend,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade400,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade700.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: _isAdding
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.person_add_outlined,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          if (_addError != null) ...[
            const SizedBox(height: 12),
            _messageBanner(_addError!, isError: true),
          ],
          if (_addSuccess != null) ...[
            const SizedBox(height: 12),
            _messageBanner(_addSuccess!, isError: false),
          ],
        ],
      ),
    );
  }

  Widget _messageBanner(String text, {required bool isError}) {
    final color = isError ? Colors.red.shade700 : Colors.green.shade700;
    final textColor = isError ? Colors.red.shade400 : Colors.green.shade400;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(text,
          style: TextStyle(color: textColor, fontSize: 13)),
    );
  }

  Future<void> _submitAddFriend() async {
    final username = _addController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isAdding = true;
      _addError = null;
      _addSuccess = null;
    });

    final ok = await _friendsService.addFriend(username);

    if (mounted) {
      setState(() {
        _isAdding = false;
        if (ok) {
          _addSuccess = 'Demande envoyée à $username !';
          _addController.clear();
        } else {
          _addError = 'Utilisateur introuvable ou demande déjà envoyée';
        }
      });
    }
  }

  // ─── État vide ──────────────────────────────────────────────────────────────

  Widget _emptyState(
      {required IconData icon, required String label, String? sub}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 44),
          const SizedBox(height: 14),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w300)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  // ─── Vue non connecté ────────────────────────────────────────────────────────

  Widget _buildNotLoggedIn() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 60, color: Colors.grey.shade700),
              const SizedBox(height: 20),
              const Text(
                'AMIS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connecte-toi pour voir\ntes amis sur la carte en temps réel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade700.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'Connecte-toi dans Profil →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
