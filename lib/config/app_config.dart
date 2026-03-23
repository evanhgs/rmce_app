enum Environnement { dev, prod }

class AppConfig {
  AppConfig._();

  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String _apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000');
  static const String _geoServiceUrl = String.fromEnvironment(
      'GEO_SERVICE_URL',
      defaultValue: 'ws://10.0.2.2:8080');

  static Environnement get environnement =>
      _env == 'prod' ? Environnement.prod : Environnement.dev;

  static bool get isDev => environnement == Environnement.dev;
  static bool get isProd => environnement == Environnement.prod;
  static String get apiBaseUrl => _apiBaseUrl;
  static String get geoServiceUrl => _geoServiceUrl;
  static String get appLabel => isDev ? 'rmce_app [DEV]' : 'rmce_app';
}
