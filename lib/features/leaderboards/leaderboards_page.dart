import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../challenges/challenges_controller.dart';
import '../routes/route_explorer_controller.dart';
import '../routes/route_models.dart';
import 'leaderboards_controller.dart';

class LeaderboardsPage extends StatelessWidget {
  const LeaderboardsPage({
    super.key,
    required this.controller,
    required this.routesController,
    required this.challengesController,
  });

  final LeaderboardsController controller;
  final RouteExplorerController routesController;
  final ChallengesController challengesController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classements')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ValueListenableBuilder<RouteExplorerState>(
            valueListenable: routesController.state,
            builder: (context, routeState, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classement par parcours',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RouteModel>(
                        initialValue: controller.state.value.selectedRoute,
                        items: [
                          ...routeState.myRoutes,
                          ...routeState.publicRoutes.where(
                            (route) => !routeState.myRoutes
                                .any((myRoute) => myRoute.id == route.id),
                          ),
                        ]
                            .map(
                              (route) => DropdownMenuItem(
                                value: route,
                                child: Text(route.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (route) {
                          if (route != null) {
                            controller.selectRoute(route);
                          }
                        },
                        decoration:
                            const InputDecoration(labelText: 'Choisir un parcours'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<LeaderboardsState>(
            valueListenable: controller.state,
            builder: (context, state, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top parcours',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (state.routeLeaderboard.isEmpty)
                        const Text('Choisis un parcours pour charger le podium.')
                      else
                        ...state.routeLeaderboard.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text('${state.routeLeaderboard.indexOf(entry) + 1}'),
                            ),
                            title: Text(entry.username),
                            subtitle: Text(entry.timeSeconds == null
                                ? 'Temps indisponible'
                                : '${entry.timeSeconds!.toStringAsFixed(1)} s'),
                            trailing: Text(
                              entry.maxSpeedKmh == null
                                  ? '—'
                                  : formatSpeed(entry.maxSpeedKmh!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<LeaderboardsState>(
            valueListenable: controller.state,
            builder: (context, state, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top vitesses globales',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...state.globalSpeedLeaderboard.take(10).map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.username),
                              subtitle: Text(formatDateTime(entry.createdAt)),
                              trailing: Text(
                                entry.maxSpeedKmh == null
                                    ? '—'
                                    : formatSpeed(entry.maxSpeedKmh!),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<ChallengesState>(
            valueListenable: challengesController.state,
            builder: (context, state, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Défis disponibles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (state.availableChallenges.isEmpty)
                        const Text('Aucun défi ouvert pour le moment.')
                      else
                        ...state.availableChallenges.map(
                          (challenge) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Parcours #${challenge.routeId}'),
                            subtitle: Text('Créé le ${formatDateTime(challenge.createdAt)}'),
                            trailing: Text(challenge.status),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
