import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  final String title;

  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  bool _showLogin = true; // bascule entre connexion et inscription

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Formulaire connexion
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginPasswordVisible = false;

  // Formulaire inscription
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _registerPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _verifierStatutAuth();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifierStatutAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    final user = await _authService.getUser();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _user = user;
      });
    }
  }

  Future<void> _connecter() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.login(email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _isLoggedIn = true;
          _user = result['user'] as Map<String, dynamic>?;
          _loginEmailController.clear();
          _loginPasswordController.clear();
        } else {
          _errorMessage = result['message'] as String?;
        }
      });
    }
  }

  Future<void> _inscrire() async {
    final username = _registerUsernameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.register(username, email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _successMessage = 'Compte créé ! Vous pouvez maintenant vous connecter.';
          _showLogin = true;
          _registerUsernameController.clear();
          _registerEmailController.clear();
          _registerPasswordController.clear();
        } else {
          _errorMessage = result['message'] as String?;
        }
      });
    }
  }

  Future<void> _deconnecter() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _user = null;
        _errorMessage = null;
        _successMessage = null;
      });
    }
  }

  void _basculerFormulaire(bool versConnexion) {
    setState(() {
      _showLogin = versConnexion;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  // ─── Build principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoggedIn ? _vueConnecte() : _vueAuth(),
      ),
    );
  }

  // ─── Vue compte connecté ────────────────────────────────────────────────────

  Widget _vueConnecte() {
    final username = _user?['username'] as String? ?? '—';
    final email = _user?['email'] as String? ?? '—';
    final userId = _user?['id']?.toString() ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Avatar + info
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade900,
                    border: Border.all(color: Colors.blue.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade400.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, size: 40, color: Colors.blue.shade400),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Carte infos
          _carteInfos('COMPTE', [
            _ligneInfo(Icons.badge_outlined, 'Identifiant', '#$userId'),
            _ligneInfo(Icons.person_outline, 'Pseudo', username),
            _ligneInfo(Icons.email_outlined, 'Email', email),
          ]),

          const SizedBox(height: 32),

          // Bouton déconnexion
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _deconnecter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade700, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'SE DÉCONNECTER',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteInfos(String titre, List<Widget> lignes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...lignes,
        ],
      ),
    );
  }

  Widget _ligneInfo(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
          const Spacer(),
          Text(
            valeur,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vue authentification ───────────────────────────────────────────────────

  Widget _vueAuth() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Icône
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade900,
              border: Border.all(color: Colors.blue.shade700.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(Icons.lock_outline, size: 32, color: Colors.blue.shade400),
          ),

          const SizedBox(height: 24),

          // Bascule connexion / inscription
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Row(
              children: [
                _ongletBascule('CONNEXION', _showLogin, () => _basculerFormulaire(true)),
                _ongletBascule('INSCRIPTION', !_showLogin, () => _basculerFormulaire(false)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Message succès
          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade700),
              ),
              child: Text(
                _successMessage!,
                style: TextStyle(color: Colors.green.shade400, fontSize: 13),
              ),
            ),

          // Message erreur
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 13),
              ),
            ),

          // Formulaire actif
          _showLogin ? _formulaireConnexion() : _formulaireInscription(),
        ],
      ),
    );
  }

  Widget _ongletBascule(String label, bool actif, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: actif ? Colors.blue.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: actif ? Colors.white : Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Formulaire connexion ───────────────────────────────────────────────────

  Widget _formulaireConnexion() {
    return Column(
      children: [
        _champTexte(
          controller: _loginEmailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _champTexte(
          controller: _loginPasswordController,
          label: 'Mot de passe',
          icon: Icons.lock_outline,
          obscureText: !_loginPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _loginPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
          ),
        ),
        const SizedBox(height: 28),
        _boutonAction(
          label: 'SE CONNECTER',
          isLoading: _isLoading,
          onTap: _connecter,
        ),
      ],
    );
  }

  // ─── Formulaire inscription ─────────────────────────────────────────────────

  Widget _formulaireInscription() {
    return Column(
      children: [
        _champTexte(
          controller: _registerUsernameController,
          label: 'Pseudo',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _champTexte(
          controller: _registerEmailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _champTexte(
          controller: _registerPasswordController,
          label: 'Mot de passe',
          icon: Icons.lock_outline,
          obscureText: !_registerPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _registerPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () => setState(() => _registerPasswordVisible = !_registerPasswordVisible),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '8 caractères minimum, avec majuscule et caractère spécial',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _boutonAction(
          label: 'CRÉER UN COMPTE',
          isLoading: _isLoading,
          onTap: _inscrire,
        ),
      ],
    );
  }

  // ─── Widgets réutilisables ──────────────────────────────────────────────────

  Widget _champTexte({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _boutonAction({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade700.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}

