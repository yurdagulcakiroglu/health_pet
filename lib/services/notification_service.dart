import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._(); // singleton
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Uygulama açılırken çağır
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    // Time-zone paketi
    tz.initializeTimeZones();
  }

  /// Tek seferlik bildirim
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),

      // ---- Bildirim detayları ----
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel', // channel id
          'Hatırlatıcılar', // channel name
          channelDescription: 'Pet hatırlatıcı bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // Opsiyoneller
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'reminder',
    );
  }

  /// Bildirimi iptal et
  Future<void> cancel(int id) => _plugin.cancel(id);
}
