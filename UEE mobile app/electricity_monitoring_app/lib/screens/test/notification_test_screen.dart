import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/weekly_budget_notification_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class NotificationTestScreen extends StatefulWidget {
  static const routeName = '/notification-test';

  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final WeeklyBudgetNotificationService _weeklyService =
      WeeklyBudgetNotificationService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _weeklyService.getNotificationStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading stats: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testBudgetExceeded() async {
    setState(() => _isLoading = true);
    try {
      await _weeklyService.testBudgetExceeded();
      _showSnackBar(
        'Budget exceeded notification sent! Check your phone and app.',
        Colors.orange,
      );
      await _loadStats();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testBudgetWithin() async {
    setState(() => _isLoading = true);
    try {
      await _weeklyService.testBudgetWithin();
      _showSnackBar(
        'Budget within notification sent! Check your phone and app.',
        Colors.green,
      );
      await _loadStats();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testWeekStartReminder() async {
    setState(() => _isLoading = true);
    try {
      await _weeklyService.testWeeklyReminder(customWeek: 1, isStart: true);
      _showSnackBar(
        'Week start reminder sent! Check your phone and app.',
        Colors.blue,
      );
      await _loadStats();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testWeekEndReminder() async {
    setState(() => _isLoading = true);
    try {
      await _weeklyService.testWeeklyReminder(customWeek: 1, isStart: false);
      _showSnackBar(
        'Week end reminder sent! Check your phone and app.',
        Colors.blue,
      );
      await _loadStats();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testDailyCheck() async {
    setState(() => _isLoading = true);
    try {
      await _weeklyService.checkDailyReminder();
      _showSnackBar(
        'Daily check executed! Notification sent if today is a reminder day.',
        Colors.purple,
      );
      await _loadStats();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _clearTestNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Notifications?'),
        content: const Text(
          'This will remove all test notifications from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _weeklyService.clearTestNotifications();
        _showSnackBar('Test notifications cleared!', Colors.green);
        await _loadStats();
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUnreadCount() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final count = await _notificationService.getUnreadNotificationsCount(
          user.uid,
        );
        _showSnackBar('You have $count unread notifications', Colors.blue);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notification System Test'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.science, color: Colors.white, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Notification Testing Lab',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Test all notification features here',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Section
                  const Text(
                    'Notification Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Total Notifications',
                          '${_stats['total'] ?? 0}',
                          Icons.notifications,
                          Colors.blue,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Budget Notifications',
                          '${_stats['budgetNotifications'] ?? 0}',
                          Icons.account_balance_wallet,
                          Colors.purple,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Within Budget Count',
                          '${_stats['withinBudgetCount'] ?? 0}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Exceeded Budget Count',
                          '${_stats['exceededBudgetCount'] ?? 0}',
                          Icons.warning,
                          Colors.red,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Reminder Notifications',
                          '${_stats['reminderNotifications'] ?? 0}',
                          Icons.alarm,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Budget Status Tests
                  const Text(
                    'Budget Status Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Budget Exceeded',
                    description:
                        'Simulate week usage exceeding allocated budget',
                    icon: Icons.trending_up,
                    color: Colors.red,
                    onPressed: _testBudgetExceeded,
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Budget Within',
                    description: 'Simulate week usage within allocated budget',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onPressed: _testBudgetWithin,
                  ),
                  const SizedBox(height: 24),

                  // Weekly Reminder Tests
                  const Text(
                    'Weekly Reminder Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Week Start Reminder',
                    description: 'Test notification for days 1, 8, 15, 22',
                    icon: Icons.play_circle_outline,
                    color: Colors.blue,
                    onPressed: _testWeekStartReminder,
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Week End Reminder',
                    description: 'Test notification for days 28, 29, 30, 31',
                    icon: Icons.stop_circle,
                    color: Colors.indigo,
                    onPressed: _testWeekEndReminder,
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Daily Check (Real)',
                    description:
                        'Check if today is a reminder day and send notification',
                    icon: Icons.today,
                    color: Colors.purple,
                    onPressed: _testDailyCheck,
                  ),
                  const SizedBox(height: 24),

                  // System Tests
                  const Text(
                    'System Tests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Check Unread Count',
                    description: 'Get current unread notifications count',
                    icon: Icons.fiber_manual_record,
                    color: Colors.teal,
                    onPressed: _checkUnreadCount,
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'View Notifications',
                    description: 'Open notifications screen',
                    icon: Icons.list,
                    color: Colors.cyan,
                    onPressed: () {
                      Navigator.pushNamed(context, '/new-notifications');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Clear Test Notifications',
                    description: 'Remove all test notifications from database',
                    icon: Icons.delete_sweep,
                    color: Colors.grey,
                    onPressed: _clearTestNotifications,
                  ),
                  const SizedBox(height: 24),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How It Works',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          '✅ Notifications are sent to your phone AND saved in the app',
                        ),
                        _buildInfoItem(
                          '📱 Check your notification tray for phone notifications',
                        ),
                        _buildInfoItem(
                          '📊 View in-app notifications from the bell icon in dashboard',
                        ),
                        _buildInfoItem(
                          '🔔 Budget status sent when you calculate week kWh',
                        ),
                        _buildInfoItem(
                          '📅 Weekly reminders sent on days: 1, 8, 15, 22, 28, 29, 30, 31',
                        ),
                        _buildInfoItem(
                          '🧪 Test notifications are marked and can be cleared',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.amber.shade900,
          height: 1.4,
        ),
      ),
    );
  }
}
