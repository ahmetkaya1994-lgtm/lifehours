import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Bildirim ID'leri
  static const int kBudgetWarningId = 1;
  static const int kMonthlyReportId = 2;
  static const int kDailyReminderId = 3;

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 13+ izin iste
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse response) {
    // İleride deep link eklenebilir
  }

  // ── Kanal ayarları ─────────────────────────────────────────────────────────
  AndroidNotificationDetails get _budgetChannel =>
      const AndroidNotificationDetails(
        'budget_warning',
        'Budget Warnings',
        channelDescription: 'Alerts when you are close to your monthly budget',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  AndroidNotificationDetails get _reportChannel =>
      const AndroidNotificationDetails(
        'monthly_report',
        'Monthly Reports',
        channelDescription: 'Monthly AI spending report notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

  AndroidNotificationDetails get _dailyChannel =>
      const AndroidNotificationDetails(
        'daily_reminder',
        'Daily Reminders',
        channelDescription: 'Daily spending tracker reminders',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      );

  // ── 1. Bütçe %80 uyarısı (in-app tetiklemeli) ─────────────────────────────
  Future<void> showBudgetWarning({
    required double spentPct,
    required String spentTime,
    required String budgetTime,
    String currency = '',
    double spentMoney = 0,
  }) async {
    final pct = (spentPct * 100).round();
    final moneyNote = spentMoney > 0
        ? '  ·  ${currency}${spentMoney.toStringAsFixed(2)} spent'
        : '';
    await _plugin.show(
      kBudgetWarningId,
      '⚠️ Budget at $pct%',
      'You\'ve spent $spentTime of your $budgetTime monthly budget.$moneyNote',
      NotificationDetails(android: _budgetChannel),
    );
  }

  // ── 2. Ay sonu rapor bildirimi (schedule) ─────────────────────────────────
  Future<void> scheduleMonthlyReport() async {
    await _plugin.cancel(kMonthlyReportId);

    final now = DateTime.now();
    // Her ayın son günü saat 19:00
    final lastDay = DateTime(now.year, now.month + 1, 0, 19, 0);
    if (lastDay.isBefore(now)) return;

    await _plugin.zonedSchedule(
      kMonthlyReportId,
      '📊 Your ${_monthName(now.month)} Report is Ready',
      'See how many hours you spent this month and get AI insights.',
      tz.TZDateTime.from(lastDay, tz.local),
      NotificationDetails(android: _reportChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // ── 3. Günlük hatırlatıcı (schedule) ──────────────────────────────────────
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await _plugin.cancel(kDailyReminderId);

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      kDailyReminderId,
      '⏱️ Track Today\'s Spending',
      'Did you buy anything today? Keep your LifeHours up to date.',
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(android: _dailyChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(kDailyReminderId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m];
  }
}
