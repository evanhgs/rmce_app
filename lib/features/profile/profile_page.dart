import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.authController,
    required this.profileController,
  });

  final AuthController authController;
  final ProfileController profileController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _registerUsernameController =
      TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();

  bool _showLogin = true;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: widget.authController.state,
      builder: (context, authState, _) {
        if (!authState.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('Connexion'),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Inscription'),
                            ),
                          ],
                          selected: {_showLogin},
                          onSelectionChanged: (selection) {
                            setState(() => _showLogin = selection.first);
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_showLogin) ...[
                          TextField(
                            controller: _loginEmailController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _loginPasswordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Mot de passe'),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => widget.authController.login(
                              _loginEmailController.text.trim(),
                              _loginPasswordController.text,
                            ),
                            child: const Text('Se connecter'),
                          ),
                        ] else ...[
                          TextField(
                            controller: _registerUsernameController,
                            decoration:
                                const InputDecoration(labelText: 'Pseudo'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerEmailController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerPasswordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Mot de passe'),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => widget.authController.register(
                              _registerUsernameController.text.trim(),
                              _registerEmailController.text.trim(),
                              _registerPasswordController.text,
                            ),
                            child: const Text('Créer un compte'),
                          ),
                        ],
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            authState.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        if (authState.successMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            authState.successMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<ProfileState>(
          valueListenable: widget.profileController.state,
          builder: (context, profileState, _) {
            final user = authState.user ?? const <String, dynamic>{};
            return Scaffold(
              appBar: AppBar(title: const Text('Profil')),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username']?.toString() ?? 'Utilisateur',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(user['email']?.toString() ?? ''),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('ID #${user['id']}')),
                              Chip(
                                label: Text(
                                  '${profileState.pendingUploads} envoi(s) en attente',
                                ),
                              ),
                              const Chip(label: Text('Android: fond prioritaire')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: widget.authController.logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Se déconnecter'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes parcours',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...profileState.myRoutes.map(
                            (route) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(route.name),
                              subtitle: Text(
                                '${formatDistance(route.distanceMeters)} • ${route.isPublic ? 'Public' : 'Privé'}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historique local',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...profileState.history.map(
                            (summary) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(summary.routeName),
                              subtitle: Text(
                                '${formatDateTime(summary.completedAt)} • ${formatDistance(summary.metrics.distanceMeters)}',
                              ),
                              trailing: Text(formatDuration(summary.elapsed)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Permissions et batterie',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Android utilise un suivi foreground pour préserver la session active. Pense à désactiver les optimisations batterie agressives si le système coupe la mesure.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
