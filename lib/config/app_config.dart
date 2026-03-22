// Configuration d'environnement de l'application.
//
// Les valeurs sont injectées au moment du build via --dart-define-from-file.
// Les fichiers de config se trouvent à la racine du projet :
//
//   Dev  (émulateur Android) :
//     flutter run --dart-define-from-file=.env.dev.json
//
//   Prod :
//     flutter build apk --dart-define-from-file=.env.prod.json
//     flutter build appbundle --dart-define-from-file=.env.prod.json
//
// ⚠️ Ne jamais committer .env.prod.json (ajouté au .gitignore).

enum Environnement { dev, prod }

class AppConfig {
  AppConfig._(); // classe non instanciable

  // ─── Variables injectées par --dart-define-from-file ────────────────────────

  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000', // fallback émulateur Android
  );

  static const String _geoServiceUrl = String.fromEnvironment(
    'GEO_SERVICE_URL',
    defaultValue: 'ws://10.0.2.2:8080', // fallback émulateur Android
  );

  // ─── Accesseurs publics ──────────────────────────────────────────────────────

  /// Environnement actuel : [Environnement.dev] ou [Environnement.prod]
  static Environnement get environnement =>
      _env == 'prod' ? Environnement.prod : Environnement.dev;

  static bool get isDev => environnement == Environnement.dev;
  static bool get isProd => environnement == Environnement.prod;

  /// URL de base de l'API Rust (sans slash final)
  static String get apiBaseUrl => _apiBaseUrl;

  /// URL WebSocket du geo-service (sans slash final)
  static String get geoServiceUrl => _geoServiceUrl;

  /// Nom affiché dans les logs / debug banner
  static String get appLabel => isDev ? 'rmce_app [DEV]' : 'rmce_app';
}

