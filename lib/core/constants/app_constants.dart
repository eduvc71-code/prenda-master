class AppConstants {
  static const String appName = 'PrendaMaster';
  static const String appVersion = '1.0.0';

  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);

  static const int pinLength = 4;
  static const int maxPinAttempts = 5;

  static const String dbName = 'prenda_master.db';
  static const int dbVersion = 1;

  static const String prefsKeyPin = 'user_pin';
  static const String prefsKeyBiometricEnabled = 'biometric_enabled';
  static const String prefsKeyFirstLaunch = 'first_launch';
  static const String prefsKeyThemeMode = 'theme_mode';

  static const String routeSplash = '/';
  static const String routeLoginPin = '/login-pin';
  static const String routeHome = '/home';
  static const String routePrestamos = '/prestamos';
  static const String routeNuevoPrestamo = '/prestamos/nuevo';
  static const String routeDetallePrestamo = '/prestamos/:id';
  static const String routeClientes = '/clientes';
  static const String routeNuevoCliente = '/clientes/nuevo';
  static const String routePagos = '/pagos';
  static const String routeAlertas = '/alertas';
  static const String routeReportes = '/reportes';
  static const String routeBackup = '/backup';

  static const List<String> monedas = ['USD', 'MXN', 'EUR', 'COP', 'ARS', 'CLP', 'PEN'];
  static const String monedaDefault = 'USD';

  static const double interesMensualDefault = 0.03; // 3% mensual
  static const int diasVencimientoDefault = 30;

  static const String googleDriveBackupFolder = 'PrendaMaster_Backups';
  static const Duration backupInterval = Duration(days: 1);
}
