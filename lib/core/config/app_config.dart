/// Application environment configuration.
///
/// The active environment is set at build time via --dart-define:
///   flutter run --dart-define=APP_ENV=local        (default)
///   flutter run --dart-define=APP_ENV=staging
///   flutter run --dart-define=APP_ENV=production
enum AppEnv { local, staging, production }

abstract class AppConfig {
  static const String _envName =
      String.fromEnvironment('APP_ENV', defaultValue: 'local');

  static final AppEnv _current = switch (_envName) {
    'staging' => AppEnv.staging,
    'production' => AppEnv.production,
    _ => AppEnv.local,
  };

  /// Base URL for the REST API (no trailing slash).
  static String get apiBaseUrl {
    switch (_current) {
      case AppEnv.local:
        // IIS Express only binds to localhost — use the Kestrel HTTP profile instead.
        // Run the API with: dotnet run --launch-profile http
        // Android emulator: 10.0.2.2 maps to host machine localhost.
        // iOS simulator: use 'localhost' instead.
        return 'http://10.0.2.2:5112';
      case AppEnv.staging:
        return 'https://staging-api.financecontrol.example.com';
      case AppEnv.production:
        return 'https://api.financecontrol.example.com';
    }
  }

  /// Whether the app should bypass SSL certificate verification.
  /// MUST be false in staging and production.
  static bool get allowBadCertificate => _current == AppEnv.local;

  /// Current environment label (useful for debug banners).
  static String get envLabel => _current.name;
}
