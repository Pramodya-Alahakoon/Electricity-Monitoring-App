import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/usage_notifier_service.dart';
import '../services/meter_reading_reminder_service.dart';
import '../services/weekly_budget_notification_service.dart';

/// The entry point for the background worker process.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Initialize the worker and register the task callback
  Workmanager().executeTask((task, inputData) async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    try {
      debugPrint('Executing background task: $task');

      // Initialize Firebase in background context
      await Firebase.initializeApp();
      debugPrint('Firebase initialized in background task');

      // Check what task we're executing
      if (task == 'checkUsage') {
        debugPrint('Starting usage check for all users');

        // Create an instance of the usage notifier
        final notifier = UsageNotifier();

        // Give Firebase a moment to fully initialize
        await Future.delayed(const Duration(seconds: 2));

        // Check usage for all users
        await notifier.checkAllUsers();

        debugPrint('Usage check completed successfully');
      }
      // Check for meter reading reminders
      else if (task == 'checkMeterReadingReminder') {
        debugPrint('Checking meter reading reminder');

        // Create an instance of the meter reading reminder service
        final meterReadingService = MeterReadingReminderService();

        // Give Firebase a moment to fully initialize
        await Future.delayed(const Duration(seconds: 2));

        // Check and send meter reading reminders
        await meterReadingService.checkAndSendMeterReadingReminder();

        debugPrint('Meter reading reminder check completed successfully');
      }
      // Check for weekly budget notifications (daily reminders on specific days)
      else if (task == 'checkWeeklyBudgetReminder') {
        debugPrint('Checking weekly budget reminders');

        // Create an instance of the weekly budget notification service
        final weeklyBudgetService = WeeklyBudgetNotificationService();

        // Give Firebase a moment to fully initialize
        await Future.delayed(const Duration(seconds: 2));

        // Check and send daily reminders if today is a reminder day
        await weeklyBudgetService.checkDailyReminder();

        debugPrint('Weekly budget reminder check completed successfully');
      }

      // Always return true for work completion
      return Future.value(true);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error in background task: ${e.message}');
      return Future.value(false);
    } catch (e) {
      debugPrint('Error in background task: $e');
      // Return false to indicate task failure
      return Future.value(false);
    }
  });
}

/// Initialize the workmanager and register tasks
Future<void> initializeWorkManager() async {
  try {
    // Initialize the workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode:
          false, // Set to false in production to avoid excessive logging
    );

    // Register the periodic task to check usage
    await Workmanager().registerPeriodicTask(
      "usageCheckTask", // Unique task name
      "checkUsage", // Task type
      frequency: const Duration(
        hours: 1,
      ), // Check every hour instead of 15 minutes
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Register the periodic task to check meter reading reminders
    // This runs once per day to check if it's Monday (week start) or Sunday (week end)
    await Workmanager().registerPeriodicTask(
      "meterReadingReminderTask", // Unique task name
      "checkMeterReadingReminder", // Task type
      frequency: const Duration(hours: 24), // Check once per day
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      initialDelay: const Duration(hours: 8), // Start at 8 AM
    );

    // Register the periodic task to check weekly budget reminders
    // This runs once per day to check if today is a reminder day (1, 8, 15, 22, 28, 29, 30, 31)
    await Workmanager().registerPeriodicTask(
      "weeklyBudgetReminderTask", // Unique task name
      "checkWeeklyBudgetReminder", // Task type
      frequency: const Duration(hours: 24), // Check once per day
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      initialDelay: const Duration(hours: 8), // Start at 8 AM
    );

    debugPrint('Workmanager initialized and tasks registered successfully');
  } catch (e) {
    debugPrint('Error initializing Workmanager: $e');
  }
}
