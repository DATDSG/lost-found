import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  int _badge = 0;
  final _badgeController = StreamController<int>.broadcast();

  Stream<int> get badgeStream => _badgeController.stream;
  int get badgeCount => _badge;

  /// Call once on app start.
  Future<void> init() async {
    tzdata.initializeTimeZones();

    // ---- Initialization (channels/icons already in AndroidManifest) ----
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const init = InitializationSettings(android: android, iOS: ios);

    await _fln.initialize(init, onDidReceiveNotificationResponse: (resp) {});

    // ---- Android 8.0+ channel (id must match when showing) ----
    const ch = AndroidNotificationChannel(
      'default_channel',
      'General',
      description: 'General notifications',
      importance: Importance.high,
    );
    await _fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(ch);

    // ---- Runtime permission prompts ----
    // Android 13+ notifications permission:
    await _fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // (On iOS we already requested in DarwinInitializationSettings)
  }

  void dispose() {
    _badgeController.close();
  }

  void _bumpBadge([int delta = 1]) {
    _badge = (_badge + delta).clamp(0, 999);
    _badgeController.add(_badge);
  }

  Future<void> clearBadge() async {
    _badge = 0;
    _badgeController.add(_badge);
    await _fln.cancelAll(); // ✅ replaces clearAll()
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'default_channel',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: DefaultStyleInformation(true, true),
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }

  // ---------- Types ----------
  Future<void> instant(String title, String body) async {
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _details(),
    );
    _bumpBadge();
  }

  Future<void> inbox(String title, List<String> lines) async {
    final android = AndroidNotificationDetails(
      'default_channel',
      'General',
      styleInformation: InboxStyleInformation(lines, contentTitle: title),
      importance: Importance.high,
      priority: Priority.high,
    );
    await _fln.show(
      DateTime.now().hashCode,
      title,
      lines.join(' • '),
      NotificationDetails(
        android: android,
        iOS: const DarwinNotificationDetails(),
      ),
    );
    _bumpBadge();
  }

  Future<void> progress(
    String title, {
    int max = 100,
    Duration step = const Duration(milliseconds: 80),
  }) async {
    final id = DateTime.now().hashCode;
    for (int i = 0; i <= max; i += 5) {
      final android = AndroidNotificationDetails(
        'default_channel',
        'General',
        showProgress: true,
        maxProgress: max,
        progress: i,
        onlyAlertOnce: true,
        importance: Importance.low,
        priority: Priority.low,
      );
      await _fln.show(
        id,
        title,
        '$i%',
        NotificationDetails(android: android),
      );
      await Future.delayed(step);
    }
    _bumpBadge();
  }

  /// One-shot scheduled notification (e.g., 5s later).
  Future<void> scheduleIn(String title, String body, Duration inFromNow) async {
    final when = tz.TZDateTime.now(tz.local).add(inFromNow);
    await _fln.zonedSchedule(
      DateTime.now().hashCode,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // NOTE: Older plugin versions don’t support these params; keep it minimal.
      // If your IDE flags args, simply remove them — defaults are fine.
      uiLocalNotificationDateInterpretation: null, // remove if your version errors
      payload: null,
    );
    _bumpBadge();
  }

  // Simple in-app banner (SnackBar)
  void inAppBanner(BuildContext context, String title, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
