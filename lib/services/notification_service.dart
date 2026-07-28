import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // 通知渠道 ID
  static const String todoChannelId = 'todo_reminder';
  static const String dailyChannelId = 'daily_checkin';
  static const String usageChannelId = 'usage_alert';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 创建通知渠道
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        todoChannelId,
        '待办提醒',
        description: '待办事项到期或提前提醒',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        dailyChannelId,
        '每日打卡',
        description: '每日早晚打卡提醒',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        usageChannelId,
        '使用时长提醒',
        description: '应用使用时长超限提醒',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // 点击通知的处理逻辑 — 由 main.dart 中的回调处理
  }

  /// 安排待办提醒
  Future<void> scheduleTodoReminder({
    required int id,
    required String title,
    required DateTime remindTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      '待办提醒',
      '⏰ $title',
      tz.TZDateTime.from(remindTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          todoChannelId,
          '待办提醒',
          channelDescription: '待办事项提醒',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// 取消待办提醒
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// 每日打卡提醒
  Future<void> scheduleDailyCheckin({
    required int hour,
    required int minute,
    required String message,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      hour * 100 + minute, // 用时间做 ID
      '自律打卡',
      message,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          dailyChannelId,
          '每日打卡',
          channelDescription: '每日打卡提醒',
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 使用时长超限提醒
  Future<void> showUsageAlert(String appName, int limitMinutes) async {
    await _plugin.show(
      9999,
      '使用时长提醒',
      '⚠️ $appName 使用已超过 ${limitMinutes}分钟限制',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          usageChannelId,
          '使用时长提醒',
          channelDescription: '应用使用时长超限',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// 普通即时通知
  Future<void> showNotification(String title, String body) async {
    await _plugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          todoChannelId,
          '待办提醒',
          channelDescription: '待办提醒',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
