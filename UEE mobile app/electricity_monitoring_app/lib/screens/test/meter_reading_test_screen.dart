import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electricity_monitoring_app/services/meter_reading_reminder_service.dart';
import 'package:electricity_monitoring_app/widgets/custom_app_bar.dart';
import 'package:electricity_monitoring_app/widgets/custom_button.dart';
import 'package:electricity_monitoring_app/theme/app_colors.dart';

class MeterReadingTestScreen extends StatefulWidget {
  static const routeName = '/meter-reading-test';

  const MeterReadingTestScreen({super.key});

  @override
  State<MeterReadingTestScreen> createState() => _MeterReadingTestScreenState();
}

class _MeterReadingTestScreenState extends State<MeterReadingTestScreen> {
  bool _isLoading = false;
  bool _remindersEnabled = true;
  Map<String, dynamic>? _stats;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = Provider.of<MeterReadingReminderService>(
        context,
        listen: false,
      );
      final enabled = await service.areMeterReadingRemindersEnabled();
      final stats = await service.getMeterReadingStats();

      setState(() {
        _remindersEnabled = enabled;
        _stats = stats;
        _statusMessage = _getStatusMessage();
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusMessage() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday

    if (dayOfWeek == 1) {
      return '📅 Today is Monday - Week Start!\nYou should receive a reminder to enter your meter reading.';
    } else if (dayOfWeek == 7) {
      return '📅 Today is Sunday - Week End!\nYou should receive a reminder to enter your meter reading.';
    } else {
      final daysUntilMonday = (8 - dayOfWeek) % 7;
      final daysUntilSunday = (7 - dayOfWeek) % 7;
      final nextReminderDay = daysUntilMonday < daysUntilSunday
          ? 'Monday'
          : 'Sunday';
      final daysUntilNext = daysUntilMonday < daysUntilSunday
          ? daysUntilMonday
          : daysUntilSunday;

      return '📅 Next reminder in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'} ($nextReminderDay)';
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = Provider.of<MeterReadingReminderService>(
        context,
        listen: false,
      );
      await service.sendTestNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent! Check your notifications.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = Provider.of<MeterReadingReminderService>(
        context,
        listen: false,
      );
      await service.checkAndSendMeterReadingReminder();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder check complete! If today is Monday or Sunday, you should receive a notification.',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      await _loadStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = Provider.of<MeterReadingReminderService>(
        context,
        listen: false,
      );
      await service.setMeterReadingRemindersEnabled(!_remindersEnabled);

      await _loadStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _remindersEnabled
                ? 'Meter reading reminders enabled'
                : 'Meter reading reminders disabled',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Meter Reading Test', showBackButton: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and description
                  Center(
                    child: Icon(
                      Icons.electric_meter,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Meter Reading Reminders',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Test and manage your weekly meter reading notifications',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30),

                  // Status card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _remindersEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color: _remindersEnabled
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Reminders: ${_remindersEnabled ? "Enabled ✓" : "Disabled ✗"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _remindersEnabled
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(_statusMessage, style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // How it works section
                  Card(
                    elevation: 2,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              SizedBox(width: 10),
                              Text(
                                'How It Works',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          _buildInfoRow(
                            '📱',
                            'Automatic notifications on Mondays and Sundays',
                          ),
                          _buildInfoRow('🔔', 'Reminders sent at 8:00 AM'),
                          _buildInfoRow(
                            '📊',
                            'Week starts on Monday, ends on Sunday',
                          ),
                          _buildInfoRow(
                            '⚡',
                            'Helps you track weekly electricity usage',
                          ),
                          _buildInfoRow('✅', 'Never miss your meter readings'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Statistics section
                  if (_stats != null && _stats!.isNotEmpty)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistics (Last 4 Weeks)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildStatRow(
                              'Total Reminders Sent',
                              '${_stats!['totalReminders'] ?? 0}',
                            ),
                            _buildStatRow(
                              'Week Start Reminders',
                              '${_stats!['weekStartReminders'] ?? 0}',
                            ),
                            _buildStatRow(
                              'Week End Reminders',
                              '${_stats!['weekEndReminders'] ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 30),

                  // Action buttons
                  Center(
                    child: CustomButton(
                      text: 'Send Test Notification',
                      onPressed: _sendTestNotification,
                      width: 250,
                      icon: Icons.send,
                    ),
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: CustomButton(
                      text: 'Check for Reminders',
                      onPressed: _checkReminders,
                      width: 250,
                      icon: Icons.check_circle,
                    ),
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: CustomButton(
                      text: _remindersEnabled
                          ? 'Disable Reminders'
                          : 'Enable Reminders',
                      onPressed: _toggleReminders,
                      width: 250,
                      isPrimary: !_remindersEnabled,
                      icon: _remindersEnabled
                          ? Icons.notifications_off
                          : Icons.notifications_active,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
