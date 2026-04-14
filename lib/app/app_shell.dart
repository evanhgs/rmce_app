import 'package:flutter/material.dart';

import '../core/permissions/permission_coordinator.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_repository.dart';
import '../features/challenges/challenges_controller.dart';
import '../features/challenges/challenges_repository.dart';
import '../features/friends/friends_controller.dart';
import '../features/friends/friends_repository.dart';
import '../features/friends/friends_social_page.dart';
import '../features/leaderboards/leaderboards_controller.dart';
import '../features/leaderboards/leaderboards_page.dart';
import '../features/leaderboards/leaderboards_repository.dart';
import '../features/posts/posts_controller.dart';
import '../features/posts/posts_repository.dart';
import '../features/profile/profile_controller.dart';
import '../features/profile/profile_page.dart';
import '../features/routes/route_composer_controller.dart';
import '../features/routes/route_explorer_controller.dart';
import '../features/routes/routes_page.dart';
import '../features/routes/routes_repository.dart';
import '../features/run_session/chrono_dashboard_page.dart';
import '../features/run_session/run_session_controller.dart';
import '../features/run_session/run_upload_queue_service.dart';
import '../features/run_session/scores_repository.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AuthController _authController;
  late final RouteExplorerController _routeExplorerController;
  late final RouteComposerController _routeComposerController;
  late final RunSessionController _runSessionController;
  late final FriendsController _friendsController;
  late final PostsController _postsController;
  late final ChallengesController _challengesController;
  late final LeaderboardsController _leaderboardsController;
  late final ProfileController _profileController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final routesRepository = RoutesRepository();
    final scoresRepository = ScoresRepository();
    final queueService = RunUploadQueueService(
      routesRepository: routesRepository,
      scoresRepository: scoresRepository,
    );

    _authController = AuthController(repository: AuthRepository());
    _routeExplorerController =
        RouteExplorerController(repository: routesRepository);
    _routeComposerController = RouteComposerController(
      repository: routesRepository,
    );
    _runSessionController = RunSessionController(
      permissionCoordinator: PermissionCoordinator(),
      routesRepository: routesRepository,
      scoresRepository: scoresRepository,
      queueService: queueService,
    );
    _friendsController = FriendsController(repository: FriendsRepository());
    _postsController = PostsController(repository: PostsRepository());
    _challengesController =
        ChallengesController(repository: ChallengesRepository());
    _leaderboardsController =
        LeaderboardsController(repository: LeaderboardsRepository());
    _profileController = ProfileController(
      routesRepository: routesRepository,
      queueService: queueService,
    );

    _authController.state.addListener(_handleAuthChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _authController.initialize();
    await _runSessionController.initialize();
    await _postsController.load();
    await _leaderboardsController.loadGlobal();
    await _challengesController.load();
    await _loadPrivateData();
  }

  Future<void> _handleAuthChanged() async {
    await _loadPrivateData();
  }

  Future<void> _loadPrivateData() async {
    final authState = _authController.state.value;
    final userId = authState.user?['id'] as int?;
    if (authState.isLoggedIn && userId != null) {
      await _routeExplorerController.load(userId: userId);
      await _friendsController.initialize(isLoggedIn: true);
      await _profileController.load(userId: userId);
    } else {
      await _friendsController.initialize(isLoggedIn: false);
      await _profileController.load(userId: null);
    }
  }

  @override
  void dispose() {
    _authController.state.removeListener(_handleAuthChanged);
    _friendsController.dispose();
    _runSessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChronoDashboardPage(
        controller: _runSessionController,
        onOpenRoutes: () => setState(() => _currentIndex = 1),
      ),
      RoutesPage(
        authController: _authController,
        explorerController: _routeExplorerController,
        composerController: _routeComposerController,
        runSessionController: _runSessionController,
        challengesController: _challengesController,
      ),
      FriendsSocialPage(
        authController: _authController,
        friendsController: _friendsController,
        postsController: _postsController,
        challengesController: _challengesController,
      ),
      LeaderboardsPage(
        controller: _leaderboardsController,
        routesController: _routeExplorerController,
        challengesController: _challengesController,
      ),
      ProfilePage(
        authController: _authController,
        profileController: _profileController,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Chrono',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Parcours',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Amis',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Classements',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
