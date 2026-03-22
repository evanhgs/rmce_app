# AGENTS.md – rmce_app

Flutter mobile app for racing chrono and telemetry. Dart SDK `^3.11.0`.

## Architecture

Four-tab app defined in `lib/main.dart`. Tabs: **Chrono** (`home_page`), **Map** (`map_page`), **Classement** (`top_page`, stub), **Ami(e)s** (`friends_page`, stub).

**Critical:** navigation uses `IndexedStack` (not `Navigator`/routes) so all pages stay alive in memory. This is intentional — it prevents the stopwatch from resetting when switching tabs. Do not replace with a page-rebuilding approach.

## Shared GPS Service (`lib/services/gps_service.dart`)

`GPSService` is a singleton (factory constructor pattern). All pages access GPS via:
```dart
final GPSService _gpsService = GPSService(); // same instance everywhere
```
Both `home_page` and `map_page` call `_gpsService.init()` — safe because `init()` is guarded by `_isInitialized`. Data is pushed via a broadcast `StreamController<SpeedData>`. Pages subscribe in `initState` and cancel in `dispose`.

`SpeedData` fields: `speed`, `maxSpeed`, `latitude`, `longitude`, `altitude`, `accuracy`, `timestamp`. Speed is in **km/h** (converted internally from m/s: `position.speed * 3.6`).

## Sensor Conventions (`home_page.dart`)

- Accelerometer: uses `userAccelerometerEventStream` from `sensors_plus`
- **X axis** → left (negative) / right (positive)
- **Z axis** → front (positive) / back (negative)  
- Y axis is not used for G-force display
- Updates are throttled to 100 ms intervals to avoid UI overload

## Map (`map_page.dart`)

Uses `flutter_map` + `latlong2`. Tile provider is **CartoDB Voyager** (not OSM directly). Note: `flutter_osm_plugin` is listed in `pubspec.yaml` but is **not used** — `flutter_map` is the active map library.

Heading is computed manually from successive GPS positions using `atan2(lngDiff, latDiff)`. User marker is a custom `TrianglePainter` rotated to heading.

## Assets

Declared in `pubspec.yaml` and accessed by path string:
- `assets/images/green_btn.png` / `assets/images/red_btn.png` — chrono start/stop button
- `assets/models/lambo_car.glb` — 3D model rendered via `flutter_3d_controller`

## Environment Config (`lib/config/app_config.dart`)

Variables d'environnement injectées via `--dart-define-from-file` (pas de package tiers). Deux fichiers JSON à la racine :

| Fichier | Env | Suivi git |
|---|---|---|
| `.env.dev.json` | `dev` — émulateur Android (`10.0.2.2:3000`) | ✅ oui |
| `.env.prod.json` | `prod` — serveur réel | ❌ `.gitignore` |

```bash
# Dev (défaut si aucun --dart-define)
flutter run --dart-define-from-file=.env.dev.json

# Prod
flutter build apk --dart-define-from-file=.env.prod.json
flutter build appbundle --dart-define-from-file=.env.prod.json
```

`AppConfig` expose : `apiBaseUrl`, `isDev`, `isProd`, `environnement` (enum), `appLabel`.  
Ajouter une clé dans `.env.*.json` → lire avec `String.fromEnvironment('MA_CLE')` dans `AppConfig`.

## Auth Service (`lib/services/auth_service.dart`)

`AuthService` is a singleton (same factory pattern as `GPSService`). It wraps the Rust API and persists the JWT via `shared_preferences`.

```dart
final AuthService _authService = AuthService(); // même instance partout
```

Key methods: `login(email, password)`, `register(username, email, password)`, `logout()`, `isLoggedIn()`, `getToken()`, `getUser()`. All return `Future<Map<String, dynamic>>` with a `'success'` bool key.

**Base URL** vient de `AppConfig.apiBaseUrl` — changer `API_BASE_URL` dans `.env.prod.json` pour le serveur réel.

## Settings Page (`lib/pages/settings_page.dart`)

Replaces the old `FriendsPage` stub on the 4th tab (⚙️ Réglages). Two views driven by `_isLoggedIn`:
- **Logged out**: toggle card CONNEXION / INSCRIPTION with form validation, error/success banners
- **Logged in**: user avatar card (id, pseudo, email) + red logout button

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_map` | Map rendering (active) |
| `flutter_osm_plugin` | Listed but unused |
| `geolocator` | GPS position stream |
| `sensors_plus` | Accelerometer |
| `flutter_3d_controller` | GLB 3D model viewer |
| `latlong2` | `LatLng` type for flutter_map |
| `http` | REST calls to Rust API |
| `shared_preferences` | JWT token + user persistence |

## Developer Workflows

```bash
flutter pub get          # install dependencies
flutter run              # run on connected device/emulator
flutter analyze          # static analysis (flutter_lints/flutter.yaml)
flutter build apk        # Android release build
```

GPS and sensor features require a physical device or an emulator with location/sensor mocks.

## Conventions

- Code comments and UI labels are in **French** (e.g., `// Calculer la direction`, label `"Ami(e)s"`)
- Pages follow `StatefulWidget` with a required `title` String parameter
- Stub pages (`top_page`, `friends_page`) have empty `body: Center()` — ready to be filled
- UI theme: dark background (`Colors.black`), `Colors.blue.shade400` accents, `FontWeight.w200`/`w300` thin fonts

