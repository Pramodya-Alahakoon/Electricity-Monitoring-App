import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:electricity_monitoring_app/services/notification_service.dart';
import 'package:electricity_monitoring_app/models/notification_model.dart';

/// Service to handle meter reading reminders on the 1st and 7th day of each week
class MeterReadingReminderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Keys for storing last notification dates
  static const String _keyLastWeekStartNotification =
      'last_week_start_notification';
  static const String _keyLastWeekEndNotification =
      'last_week_end_notification';
  static const String _keyMeterReadingRemindersEnabled =
      'meter_reading_reminders_enabled';

  /// Initialize the service and check if notifications should be sent
  Future<void> initialize() async {
    try {
      if (_auth.currentUser == null) {
        debugPrint(
          'No user logged in, skipping meter reading reminder initialization',
        );
        return;
      }

      // Check if reminders are enabled
      final remindersEnabled = await areMeterReadingRemindersEnabled();
      if (!remindersEnabled) {
        debugPrint('Meter reading reminders are disabled');
        return;
      }

      await checkAndSendMeterReadingReminder();
    } catch (e) {
      debugPrint('Error initializing meter reading reminder service: $e');
    }
  }

  /// Check if it's time to send a meter reading reminder
  Future<void> checkAndSendMeterReadingReminder() async {
    try {
      if (_auth.currentUser == null) return;

      final now = DateTime.now();
      final currentDay = now.weekday; // 1 = Monday, 7 = Sunday

      // Check if today is the 1st day of the week (Monday)
      if (currentDay == 1) {
        await _sendWeekStartReminder(now);
      }
      // Check if today is the 7th day of the week (Sunday)
      else if (currentDay == 7) {
        await _sendWeekEndReminder(now);
      }
    } catch (e) {
      debugPrint('Error checking meter reading reminder: $e');
    }
  }

  /// Send week start (Monday) meter reading reminder
  Future<void> _sendWeekStartReminder(DateTime now) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Check if we already sent a notification today
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationDateStr = prefs.getString(
        _keyLastWeekStartNotification,
      );

      if (lastNotificationDateStr != null) {
        final lastNotificationDate = DateTime.parse(lastNotificationDateStr);
        final today = DateTime(now.year, now.month, now.day);
        final lastNotificationDay = DateTime(
          lastNotificationDate.year,
          lastNotificationDate.month,
          lastNotificationDate.day,
        );

        // If we already sent a notification today, skip
        if (today == lastNotificationDay) {
          debugPrint('Week start reminder already sent today');
          return;
        }
      }

      // Calculate week number
      final weekNumber = _getWeekNumber(now);

      // Send notification
      const title = '📊 Week Start - Meter Reading Time!';
      final message =
          'It\'s the start of Week $weekNumber! Please enter your electricity meter reading to track your weekly usage.';

      // Store notification in Firestore
      await _notificationService.storeNotification(
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.system,
        metadata: {
          'type': 'meter_reading_reminder',
          'weekDay': 'start',
          'weekNumber': weekNumber,
          'date': now.toIso8601String(),
        },
      );

      // Send local notification
      await _notificationService.sendLocalNotification(
        title: title,
        body: message,
        payload: 'meter_reading:week_start',
      );

      // Update last notification date
      await prefs.setString(
        _keyLastWeekStartNotification,
        now.toIso8601String(),
      );

      debugPrint('Week start meter reading reminder sent');
    } catch (e) {
      debugPrint('Error sending week start reminder: $e');
    }
  }

  /// Send week end (Sunday) meter reading reminder
  Future<void> _sendWeekEndReminder(DateTime now) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Check if we already sent a notification today
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationDateStr = prefs.getString(
        _keyLastWeekEndNotification,
      );

      if (lastNotificationDateStr != null) {
        final lastNotificationDate = DateTime.parse(lastNotificationDateStr);
        final today = DateTime(now.year, now.month, now.day);
        final lastNotificationDay = DateTime(
          lastNotificationDate.year,
          lastNotificationDate.month,
          lastNotificationDate.day,
        );

        // If we already sent a notification today, skip
        if (today == lastNotificationDay) {
          debugPrint('Week end reminder already sent today');
          return;
        }
      }

      // Calculate week number
      final weekNumber = _getWeekNumber(now);

      // Send notification
      const title = '📊 Week End - Meter Reading Time!';
      final message =
          'It\'s the end of Week $weekNumber! Please enter your electricity meter reading to complete your weekly tracking.';

      // Store notification in Firestore
      await _notificationService.storeNotification(
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.system,
        metadata: {
          'type': 'meter_reading_reminder',
          'weekDay': 'end',
          'weekNumber': weekNumber,
          'date': now.toIso8601String(),
        },
      );

      // Send local notification
      await _notificationService.sendLocalNotification(
        title: title,
        body: message,
        payload: 'meter_reading:week_end',
      );

      // Update last notification date
      await prefs.setString(_keyLastWeekEndNotification, now.toIso8601String());

      debugPrint('Week end meter reading reminder sent');
    } catch (e) {
      debugPrint('Error sending week end reminder: $e');
    }
  }

  /// Calculate the week number in the current month
  /// Week 1 starts on the first Monday of the month
  int _getWeekNumber(DateTime date) {
    // Find the first day of the month
    final firstDayOfMonth = DateTime(date.year, date.month, 1);

    // Find the first Monday of the month
    int daysUntilFirstMonday = (8 - firstDayOfMonth.weekday) % 7;
    if (daysUntilFirstMonday == 0 && firstDayOfMonth.weekday != 1) {
      daysUntilFirstMonday = 7;
    }

    final firstMonday = firstDayOfMonth.add(
      Duration(days: daysUntilFirstMonday),
    );

    // Calculate week number
    if (date.isBefore(firstMonday)) {
      return 1; // Days before first Monday are considered week 1
    }

    final daysSinceFirstMonday = date.difference(firstMonday).inDays;
    final weekNumber = (daysSinceFirstMonday / 7).floor() + 1;

    return weekNumber;
  }

  /// Enable or disable meter reading reminders
  Future<void> setMeterReadingRemindersEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMeterReadingRemindersEnabled, enabled);
      notifyListeners();

      debugPrint('Meter reading reminders ${enabled ? "enabled" : "disabled"}');

      if (enabled) {
        // Check immediately if we should send a reminder
        await checkAndSendMeterReadingReminder();
      }
    } catch (e) {
      debugPrint('Error setting meter reading reminders enabled: $e');
    }
  }

  /// Check if meter reading reminders are enabled
  Future<bool> areMeterReadingRemindersEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyMeterReadingRemindersEnabled) ??
          true; // Enabled by default
    } catch (e) {
      debugPrint('Error checking if meter reading reminders enabled: $e');
      return true; // Default to enabled
    }
  }

  /// Manually trigger a test notification (for testing purposes)
  Future<void> sendTestNotification() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user logged in');
        return;
      }

      const title = '🧪 Test Meter Reading Reminder';
      const message =
          'This is a test notification to remind you to enter your meter reading.';

      // Store notification in Firestore
      await _notificationService.storeNotification(
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.system,
        metadata: {
          'type': 'meter_reading_reminder_test',
          'date': DateTime.now().toIso8601String(),
        },
      );

      // Send local notification
      await _notificationService.sendLocalNotification(
        title: title,
        body: message,
        payload: 'meter_reading:test',
      );

      debugPrint('Test meter reading reminder sent');
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /// Get statistics about meter reading compliance
  Future<Map<String, dynamic>> getMeterReadingStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      // Get notifications for the last 4 weeks
      final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));

      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('metadata.type', isEqualTo: 'meter_reading_reminder')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(fourWeeksAgo))
          .get();

      final totalReminders = notifications.docs.length;

      // Count how many times user entered readings (you would check usage_records collection)
      // This is a placeholder - implement actual logic based on your data structure

      return {
        'totalReminders': totalReminders,
        'weekStartReminders': notifications.docs
            .where((doc) => doc.data()['metadata']['weekDay'] == 'start')
            .length,
        'weekEndReminders': notifications.docs
            .where((doc) => doc.data()['metadata']['weekDay'] == 'end')
            .length,
        'lastReminderDate': notifications.docs.isNotEmpty
            ? (notifications.docs.first.data()['createdAt'] as Timestamp)
                  .toDate()
            : null,
      };
    } catch (e) {
      debugPrint('Error getting meter reading stats: $e');
      return {};
    }
  }
}
