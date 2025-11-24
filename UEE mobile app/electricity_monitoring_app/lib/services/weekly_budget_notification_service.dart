import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class WeeklyBudgetNotificationService {
  static final WeeklyBudgetNotificationService _instance =
      WeeklyBudgetNotificationService._internal();

  factory WeeklyBudgetNotificationService() => _instance;

  WeeklyBudgetNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Days to send weekly reminders
  static const List<int> reminderDays = [1, 8, 15, 22, 28, 29, 30, 31];

  /// Check and send budget status notification after kWh calculation
  Future<void> checkBudgetStatus({
    required int week,
    required double actualKwh,
    required double allocatedKwh,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final isWithinBudget = actualKwh <= allocatedKwh;
      final difference = (actualKwh - allocatedKwh).abs();

      String title;
      String body;
      NotificationType type;

      if (isWithinBudget) {
        title = '✅ Week $week: Within Budget!';
        body =
            'Great job! You used ${actualKwh.toStringAsFixed(1)} kWh out of ${allocatedKwh.toStringAsFixed(1)} kWh. Keep it up!';
        type = NotificationType.goal;
      } else {
        title = '⚠️ Week $week: Budget Exceeded!';
        body =
            'You used ${actualKwh.toStringAsFixed(1)} kWh, exceeding your budget by ${difference.toStringAsFixed(1)} kWh. Try to reduce usage.';
        type = NotificationType.usageAlert;
      }

      // Send local notification to phone
      await _sendLocalNotification(
        title: title,
        body: body,
        payload: 'budget_status_week_$week',
      );

      // Store notification in Firestore for app list
      await _notificationService.storeNotification(
        userId: user.uid,
        title: title,
        message: body,
        type: type,
        metadata: {
          'week': week,
          'actualKwh': actualKwh,
          'allocatedKwh': allocatedKwh,
          'isWithinBudget': isWithinBudget,
          'category': 'budget_status',
        },
      );

      print('Budget status notification sent for week $week');
    } catch (e) {
      print('Error sending budget status notification: $e');
    }
  }

  /// Check if today is a reminder day and send notification
  Future<void> checkDailyReminder() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dayOfMonth = now.day;

      // Check if today is a reminder day
      if (!reminderDays.contains(dayOfMonth)) {
        print('Today (day $dayOfMonth) is not a reminder day');
        return;
      }

      // Check if we already sent notification today
      final prefs = await SharedPreferences.getInstance();
      final lastReminderDate = prefs.getString('last_weekly_reminder_date');
      final today = '${now.year}-${now.month}-${now.day}';

      if (lastReminderDate == today) {
        print('Weekly reminder already sent today');
        return;
      }

      // Determine which week we're in
      int currentWeek = 1;
      if (dayOfMonth <= 7) {
        currentWeek = 1;
      } else if (dayOfMonth <= 14) {
        currentWeek = 2;
      } else if (dayOfMonth <= 21) {
        currentWeek = 3;
      } else {
        currentWeek = 4;
      }

      // Determine if it's start or end of week
      bool isWeekStart = [1, 8, 15, 22].contains(dayOfMonth);
      bool isWeekEnd =
          [28, 29, 30, 31].contains(dayOfMonth) ||
          dayOfMonth == 7 ||
          dayOfMonth == 14 ||
          dayOfMonth == 21;

      String title;
      String body;

      if (isWeekStart) {
        title = '📊 Week $currentWeek Started!';
        body =
            'Time to record your meter reading for Week $currentWeek. Track your electricity usage now!';
      } else {
        title = '📊 Week $currentWeek Ending Soon!';
        body =
            'Don\'t forget to record your final meter reading for Week $currentWeek before it ends.';
      }

      // Send local notification to phone
      await _sendLocalNotification(
        title: title,
        body: body,
        payload: 'weekly_reminder_week_$currentWeek',
      );

      // Store notification in Firestore for app list
      await _notificationService.storeNotification(
        userId: user.uid,
        title: title,
        message: body,
        type: NotificationType.system,
        metadata: {
          'week': currentWeek,
          'dayOfMonth': dayOfMonth,
          'isWeekStart': isWeekStart,
          'isWeekEnd': isWeekEnd,
          'category': 'weekly_reminder',
        },
      );

      // Save that we sent notification today
      await prefs.setString('last_weekly_reminder_date', today);

      print(
        'Weekly reminder notification sent for day $dayOfMonth (Week $currentWeek)',
      );
    } catch (e) {
      print('Error sending daily reminder: $e');
    }
  }

  /// Send local notification to phone
  Future<void> _sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final FlutterLocalNotificationsPlugin notifications =
          FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'weekly_budget_channel',
            'Weekly Budget Notifications',
            channelDescription: 'Notifications for weekly budget and reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error sending local notification: $e');
    }
  }

  /// Test function: Send budget exceeded notification
  Future<void> testBudgetExceeded() async {
    await checkBudgetStatus(week: 1, actualKwh: 35.5, allocatedKwh: 30.0);
  }

  /// Test function: Send budget within notification
  Future<void> testBudgetWithin() async {
    await checkBudgetStatus(week: 2, actualKwh: 25.0, allocatedKwh: 30.0);
  }

  /// Test function: Send weekly reminder notification
  Future<void> testWeeklyReminder({int? customWeek, bool? isStart}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final week = customWeek ?? 1;
      final isWeekStart = isStart ?? true;

      String title;
      String body;

      if (isWeekStart) {
        title = '📊 Week $week Started!';
        body =
            'Time to record your meter reading for Week $week. Track your electricity usage now!';
      } else {
        title = '📊 Week $week Ending Soon!';
        body =
            'Don\'t forget to record your final meter reading for Week $week before it ends.';
      }

      // Send local notification
      await _sendLocalNotification(
        title: title,
        body: body,
        payload: 'test_weekly_reminder_week_$week',
      );

      // Store in Firestore
      await _notificationService.storeNotification(
        userId: user.uid,
        title: title,
        message: body,
        type: NotificationType.system,
        metadata: {
          'week': week,
          'isWeekStart': isWeekStart,
          'category': 'weekly_reminder',
          'isTest': true,
        },
      );

      print('Test weekly reminder sent for week $week');
    } catch (e) {
      print('Error sending test reminder: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final notifications = await _notificationService.getUserNotifications(
        user.uid,
      );

      int budgetNotifications = 0;
      int reminderNotifications = 0;
      int withinBudgetCount = 0;
      int exceededBudgetCount = 0;

      for (var notification in notifications) {
        final metadata = notification.metadata;
        final category = metadata['category'] as String? ?? '';

        if (category == 'budget_status') {
          budgetNotifications++;
          final isWithinBudget = metadata['isWithinBudget'] as bool? ?? false;
          if (isWithinBudget) {
            withinBudgetCount++;
          } else {
            exceededBudgetCount++;
          }
        } else if (category == 'weekly_reminder') {
          reminderNotifications++;
        }
      }

      return {
        'total': notifications.length,
        'budgetNotifications': budgetNotifications,
        'reminderNotifications': reminderNotifications,
        'withinBudgetCount': withinBudgetCount,
        'exceededBudgetCount': exceededBudgetCount,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  /// Clear all test notifications
  Future<void> clearTestNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in notifications.docs) {
        final data = doc.data();
        final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
        if (metadata['isTest'] == true) {
          await doc.reference.delete();
        }
      }

      print('Test notifications cleared');
    } catch (e) {
      print('Error clearing test notifications: $e');
    }
  }
}
