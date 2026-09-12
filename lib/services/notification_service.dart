import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:prenda_master/data/app_database.dart';

// Initialize the timezone database
void initializeTimeZones() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Guatemala')); // Adjust to your timezone
}

// Notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize notifications
Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint('Notification tapped: ${response.payload}');
    },
  );
}

// Configure Workmanager
void setupWorkmanager() {
  Workmanager().initialize(
    callbackDispatcher, // top-level function
  );

  // Register periodic task to run every day at 9:00 AM
  Workmanager().registerPeriodicTask(
    'checkPaymentsTask',
    'checkPaymentsTask',
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run when connected to internet
    ),
  );
}

// Top-level callback function for Workmanager
// MUST be a top-level function (not a method of a class)
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'checkPaymentsTask':
        await _checkAndNotifyUpcomingPayments();
        break;
    }
    return Future.value(true);
  });
}

// Function to check for upcoming payments and schedule notifications
Future<void> _checkAndNotifyUpcomingPayments() async {
  try {
    // Initialize database
    final db = AppDatabase();

    // Get current date
    final now = DateTime.now();

    // Define what we consider "upcoming" (e.g., due in the next 3 days)
    final upcomingStart = now;
    final upcomingEnd = now.add(const Duration(days: 3));

    final List<Prestamo> upcomingPrestamos = await (db.select(db.prestamos)
          ..where((t) =>
              t.fechaVencimiento.isBiggerOrEqual(Variable(upcomingStart)) &
              t.fechaVencimiento.isSmallerOrEqual(Variable(upcomingEnd)) &
              t.estado.equals('Activo')))
        .get();

    // For each upcoming prestamo, schedule a notification
    for (final prestamo in upcomingPrestamos) {
      // Calculate days until vencimiento
      final daysUntil = prestamo.fechaVencimiento.difference(now).inDays;

      // Schedule notification for 9:00 AM local time
      final tz.TZDateTime nowTZ = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        nowTZ.year,
        nowTZ.month,
        nowTZ.day,
        9, // hour
        0, // minute
      );

      // If the scheduled time has passed today, schedule for tomorrow
      final tz.TZDateTime finalScheduledDate =
          scheduledDate.isBefore(nowTZ) ? scheduledDate.add(const Duration(days: 1)) : scheduledDate;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        prestamo.id.hashCode, // Use a unique ID for each notification
        'PrendaMaster: Pago pendiente',
        'El préstamo #${prestamo.id} vence en $daysUntil días (${prestamo.fechaVencimiento.day}/${prestamo.fechaVencimiento.month}/${prestamo.fechaVencimiento.year}).',
        finalScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prestamos_channel',
            'Préstamos Notifications',
            channelDescription: 'Notifications for upcoming loan payments',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  } catch (e) {
    debugPrint('Error in _checkAndNotifyUpcomingPayments: $e');
  }
}

// Expose a function to manually trigger a check (for testing)
Future<void> triggerCheckPayments() async {
  await _checkAndNotifyUpcomingPayments();
}
