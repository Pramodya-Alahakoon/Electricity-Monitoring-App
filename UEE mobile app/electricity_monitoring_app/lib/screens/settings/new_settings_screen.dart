// ignore_for_file: unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class NewSettingsScreen extends StatefulWidget {
  static const routeName = '/new-settings';

  const NewSettingsScreen({super.key});

  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends State<NewSettingsScreen> {
  bool _isLoading = false;
  UserModel? _user;
  bool _usageAlertsEnabled = true;
  bool _tipsNotificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _appUpdatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationPreferences();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final user = await profileService.getUserProfile();
      setState(() {
        _user = user;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading profile')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotificationPreferences() async {
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final usageAlerts = await profileService.getUsageAlertsEnabled();
      final tipsNotifications = await profileService
          .getTipsNotificationsEnabled();
      final budgetAlerts = await profileService.getBudgetAlertsEnabled();
      final appUpdates = await profileService.getAppUpdatesEnabled();

      setState(() {
        _usageAlertsEnabled = usageAlerts;
        _tipsNotificationsEnabled = tipsNotifications;
        _budgetAlertsEnabled = budgetAlerts;
        _appUpdatesEnabled = appUpdates;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading preferences')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              _user?.name.isNotEmpty == true
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'email@example.com',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.kitchen,
                                label: 'Appliances',
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.pushNamed(context, '/appliances');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.account_balance_wallet,
                                label: 'Budget',
                                color: Colors.green,
                                onTap: () {
                                  Navigator.pushNamed(context, '/budget');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.analytics,
                                label: 'Analysis',
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/budget-analysis',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.leaderboard,
                                label: 'Leaderboard',
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.pushNamed(context, '/leaderboard');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.emoji_events,
                                label: 'My Badges',
                                color: Colors.amber,
                                onTap: () {
                                  Navigator.pushNamed(context, '/my-badges');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.energy_savings_leaf,
                                label: 'Energy Tips',
                                color: Colors.teal,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/energy-saving-tips',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                color: Colors.deepPurple,
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed('/new-notifications');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.science,
                                label: 'Test Notifications',
                                color: Colors.redAccent,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/notification-test',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notification Settings Section
                  // Padding(
                  //   padding: const EdgeInsets.all(16.0),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Notification Settings',
                  //         style: TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.bold,
                  //           color: Colors.black87,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 12),
                  //       Container(
                  //         decoration: BoxDecoration(
                  //           color: Colors.white,
                  //           borderRadius: BorderRadius.circular(16),
                  //           boxShadow: [
                  //             BoxShadow(
                  //               color: Colors.black.withOpacity(0.05),
                  //               blurRadius: 10,
                  //               offset: const Offset(0, 4),
                  //             ),
                  //           ],
                  //         ),
                  //         child: Column(
                  //           children: [
                  //             _buildSwitchTile(
                  //               title: 'Usage Alerts',
                  //               subtitle:
                  //                   'Get notified about unusual energy consumption',
                  //               value: _usageAlertsEnabled,
                  //               onChanged: (value) {
                  //                 setState(() => _usageAlertsEnabled = value);
                  //                 final profileService =
                  //                     Provider.of<UserProfileService>(
                  //                       context,
                  //                       listen: false,
                  //                     );
                  //                 profileService.setUsageAlertsEnabled(value);
                  //               },
                  //               icon: Icons.bolt,
                  //               color: Colors.yellow.shade700,
                  //             ),
                  //             const Divider(height: 1),
                  //             _buildSwitchTile(
                  //               title: 'Energy Saving Tips',
                  //               subtitle:
                  //                   'Receive tips to reduce electricity consumption',
                  //               value: _tipsNotificationsEnabled,
                  //               onChanged: (value) {
                  //                 setState(
                  //                   () => _tipsNotificationsEnabled = value,
                  //                 );
                  //                 final profileService =
                  //                     Provider.of<UserProfileService>(
                  //                       context,
                  //                       listen: false,
                  //                     );
                  //                 profileService.setTipsNotificationsEnabled(
                  //                   value,
                  //                 );
                  //               },
                  //               icon: Icons.tips_and_updates,
                  //               color: Colors.orange,
                  //             ),
                  //             const Divider(height: 1),
                  //             _buildSwitchTile(
                  //               title: 'Budget Alerts',
                  //               subtitle:
                  //                   'Get notified when approaching budget limits',
                  //               value: _budgetAlertsEnabled,
                  //               onChanged: (value) {
                  //                 setState(() => _budgetAlertsEnabled = value);
                  //                 final profileService =
                  //                     Provider.of<UserProfileService>(
                  //                       context,
                  //                       listen: false,
                  //                     );
                  //                 profileService.setBudgetAlertsEnabled(value);
                  //               },
                  //               icon: Icons.account_balance_wallet,
                  //               color: Colors.green,
                  //             ),
                  //             const Divider(height: 1),
                  //             _buildSwitchTile(
                  //               title: 'App Updates',
                  //               subtitle:
                  //                   'Receive notifications about new app features',
                  //               value: _appUpdatesEnabled,
                  //               onChanged: (value) {
                  //                 setState(() => _appUpdatesEnabled = value);
                  //                 final profileService =
                  //                     Provider.of<UserProfileService>(
                  //                       context,
                  //                       listen: false,
                  //                     );
                  //                 profileService.setAppUpdatesEnabled(value);
                  //               },
                  //               icon: Icons.system_update,
                  //               color: Colors.blue,
                  //             ),
                  //             const Divider(height: 1),
                  //             ListTile(
                  //               leading: Container(
                  //                 padding: const EdgeInsets.all(8),
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.purple.withOpacity(0.1),
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //                 child: const Icon(
                  //                   Icons.tune,
                  //                   color: Colors.purple,
                  //                 ),
                  //               ),
                  //               title: const Text('Advanced Settings'),
                  //               subtitle: const Text(
                  //                 'Configure personalized notification preferences',
                  //               ),
                  //               trailing: const Icon(
                  //                 Icons.arrow_forward_ios,
                  //                 size: 16,
                  //               ),
                  //               onTap: () {
                  //                 Navigator.of(
                  //                   context,
                  //                 ).pushNamed('/notification-preferences');
                  //               },
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // App Info Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
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
                              _buildInfoTile(
                                icon: Icons.info_outline,
                                label: 'About',
                                color: Colors.blue,
                                onTap: () => _showAboutDialog(context),
                              ),
                              const Divider(height: 1),
                              _buildInfoTile(
                                icon: Icons.help_outline,
                                label: 'Help & Support',
                                color: Colors.green,
                                onTap: () => _showHelpSupportDialog(context),
                              ),
                              const Divider(height: 1),
                              _buildInfoTile(
                                icon: Icons.privacy_tip_outlined,
                                label: 'Privacy Policy',
                                color: Colors.purple,
                                onTap: () => _showPrivacyPolicyDialog(context),
                              ),
                              // if (!kReleaseMode) ...[
                              //   const Divider(height: 1),
                              //   _buildInfoTile(
                              //     icon: Icons.science,
                              //     label: 'Test Notifications',
                              //     color: Colors.pink,
                              //     onTap: () {
                              //       Navigator.pushNamed(
                              //         context,
                              //         '/notification-test',
                              //       );
                              //     },
                              //   ),
                              // ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('About'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Electricity Monitoring App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Electricity Monitoring App helps you track your electricity usage, manage your power consumption, and save money on your energy bills.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Key Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Real-time electricity usage monitoring'),
              const Text('• Usage history and analytics'),
              const Text('• Bill prediction and budgeting'),
              const Text('• Energy-saving tips and recommendations'),
              const Text('• Customizable alerts and notifications'),
              const SizedBox(height: 16),
              const Text(
                'Developed by UEE Team',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const Text(
                '© 2025 All Rights Reserved',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.email),
                title: Text('Email Support'),
                subtitle: Text('support@electricityapp.com'),
              ),
              const ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone Support'),
                subtitle: Text('+1 (555) 123-4567'),
              ),
              const ListTile(
                leading: Icon(Icons.chat),
                title: Text('Live Chat'),
                subtitle: Text('Available 9 AM - 5 PM, Monday to Friday'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Last updated: October 23, 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'This Privacy Policy describes how we collect, use, and disclose your information when you use our Electricity Monitoring App.',
              ),
              const SizedBox(height: 12),
              Text(
                '1. Information We Collect',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We collect information that you provide directly to us, such as your name, email address, and electricity consumption data.',
              ),
              const SizedBox(height: 12),
              Text(
                '2. Data Security',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We take reasonable measures to help protect your personal information from loss, theft, misuse, and unauthorized access.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Profile Screen (same as in settings_screen.dart)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final user = await profileService.getUserProfile();
      setState(() {
        _user = user;
        if (user != null) {
          _nameController.text = user.name;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading profile')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final success = await profileService.updateUserProfile(
        name: _nameController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    try {
      final success = await profileService.updateUserPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update password')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating password: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              _user?.name.isNotEmpty == true
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Profile info section
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _user?.email ?? '',
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isLoading ? 'Updating...' : 'Update Profile',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Change password section
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updatePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isLoading ? 'Updating...' : 'Update Password',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
