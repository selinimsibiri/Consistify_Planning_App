import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:math';
import '/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
class NotificationManager {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(int value) async {
    List<String> motivasyon = [
      "Bugün küçük bir adım atmayı unutma! Her gün bir adım, büyük değişimlere yol açar.",
      "Hedefine bir adım daha yaklaşmak için şimdi harekete geç!",
      "Zor zamanlar geçiyor olabilir, ama unutma ki her zorluk seni daha güçlü kılar.",
      "Başarısızlık, başarıya giden yolda bir duraktır. Devam et!",
    ];

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'hourly_channel',
          'Hourly Notifications',
          channelDescription:
              'Sends notification every hour if value is not zero',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Yapılması gereken $value tane is var',
      motivasyon[Random().nextInt(motivasyon.length)],
      platformDetails,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> hourlyCheck() async {
    print("hourlyCheck fonksiyonu tetiklendi");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      print('Kullanici ID bulunamadi');
      return;
    }

    int result = await performDatabaseCheck(userId);

    if (result != 0) {
      await showNotification(result);
    }
  }

  static Future<int> performDatabaseCheck(int userId) async {
    int incompleteCount = await DatabaseHelper.instance.getTotalIncompleteTaskCount(userId);
    print('Tamamlanmamış görev sayısı: $incompleteCount');
    return incompleteCount;
  }

  // Sabah 6 ile akşam 11 arasında her saat başı alarm kur
  static Future<void> scheduleHourlyAlarms() async {
    for (int hour = 6; hour <= 23; hour++) {
      await AndroidAlarmManager.periodic(
        const Duration(hours: 24),
        hour, // alarm ID (benzersiz olmalı)
        hourlyCheck,
        startAt: _nextInstanceOfHour(hour),
        exact: false,
        wakeup: true,
      );
    }
  }

  static DateTime _nextInstanceOfHour(int hour) {
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime;
  }
}