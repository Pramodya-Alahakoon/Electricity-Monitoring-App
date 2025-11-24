import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/notification_service.dart';
import '../../services/weekly_budget_notification_service.dart';
import '../../utils/app_theme.dart';

class NewDashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const NewDashboardScreen({super.key});

  @override
  State<NewDashboardScreen> createState() => _NewDashboardScreenState();
}

class _NewDashboardScreenState extends State<NewDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();
  final WeeklyBudgetNotificationService _weeklyNotificationService =
      WeeklyBudgetNotificationService();

  bool _isLoading = true;
  int _currentSlide = 0;
  String? _currentBudgetId;
  int _totalPoints = 0; // Store current points from Firebase

  // Budget data
  Map<String, dynamic> _budgetData = {};

  // Weekly count data (separate from week1, week2, etc which are kWh)
  Map<String, String> _weekCounts = {
    'week1count1': '',
    'week1count2': '',
    'week2count1': '',
    'week2count2': '',
    'week3count1': '',
    'week3count2': '',
    'week4count1': '',
    'week4count2': '',
  };

  // Text controllers for each week
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all weeks
    for (int week = 1; week <= 4; week++) {
      _controllers['week${week}count1'] = TextEditingController();
      _controllers['week${week}count2'] = TextEditingController();
    }
    _loadBudgetData();
    _currentSlide = _getCurrentWeek() - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentSlide);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Calculate current week based on today's date
  int _getCurrentWeek() {
    final today = DateTime.now();
    final dayOfMonth = today.day;
    if (dayOfMonth <= 7) return 1;
    if (dayOfMonth <= 14) return 2;
    if (dayOfMonth <= 21) return 3;
    return 4;
  }

  // Generate budget document ID (format: "2025-10")
  String _getBudgetDocId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // Calculate days in each week for current month
  Map<String, int> _getDaysInWeeks() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return {'week1': 7, 'week2': 7, 'week3': 7, 'week4': daysInMonth - 21};
  }

  // Calculate allocated budget per week
  Map<String, double> _getAllocatedBudgets() {
    final days = _getDaysInWeeks();
    final totalDays =
        days['week1']! + days['week2']! + days['week3']! + days['week4']!;
    final monthlyKwh = (_budgetData['kwh'] ?? 120).toDouble();

    return {
      'week1': monthlyKwh * days['week1']! / totalDays,
      'week2': monthlyKwh * days['week2']! / totalDays,
      'week3': monthlyKwh * days['week3']! / totalDays,
      'week4': monthlyKwh * days['week4']! / totalDays,
    };
  }

  // Load budget data from Firebase
  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final budgetDocId = _getBudgetDocId();
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetDocId)
          .get();

      if (doc.exists) {
        setState(() {
          _budgetData = Map<String, dynamic>.from(doc.data() ?? {});
          _currentBudgetId = doc.id;

          // Load meter counts from a separate subcollection or field
          // For now, we'll store them in a separate field called 'meter_readings'
          if (_budgetData['meter_readings'] != null) {
            _weekCounts = Map<String, String>.from(
              _budgetData['meter_readings'],
            );
            // Update controllers with loaded values
            _weekCounts.forEach((key, value) {
              if (_controllers.containsKey(key)) {
                _controllers[key]!.text = value;
              }
            });
          }
        });

        // Load current points from user document
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _totalPoints = (userDoc.data()?['points'] ?? 0) as int;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading budget data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save meter counts to Firebase
  Future<void> _saveMeterCounts() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _currentBudgetId == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(_currentBudgetId)
          .update({
            'meter_readings': _weekCounts,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error saving meter counts: $e');
    }
  }

  // Save weekly kWh to Firebase
  Future<void> _saveWeeklyKwh(int week, double kwh) async {
    try {
      final user = _auth.currentUser;
      if (user == null || _currentBudgetId == null) return;

      // Get old week value to check previous status
      final oldKwh = (_budgetData['week$week'] ?? 0).toDouble();
      final allocated = _getAllocatedBudgets()['week$week']!;

      // Check old status (was it within budget?)
      final wasWithinBudget = oldKwh > 0 && oldKwh <= allocated;

      // Check new status (is it within budget?)
      final isWithinBudget = kwh > 0 && kwh <= allocated;

      // Calculate point change
      int pointChange = 0;
      if (!wasWithinBudget && isWithinBudget) {
        // Changed from over budget (or no data) to within budget: ADD 10 points
        pointChange = 10;
      } else if (wasWithinBudget && !isWithinBudget) {
        // Changed from within budget to over budget: SUBTRACT 10 points
        pointChange = -10;
      }
      // If both were within budget or both over budget, no change

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(_currentBudgetId)
          .update({
            'week$week': kwh,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update local data
      setState(() {
        _budgetData['week$week'] = kwh;
      });

      // Update points if there's a change
      if (pointChange != 0) {
        await _adjustPoints(pointChange);
      }
    } catch (e) {
      debugPrint('Error saving weekly kWh: $e');
    }
  }

  // Adjust points by adding or subtracting
  Future<void> _adjustPoints(int change) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current points from Firebase
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      int currentPoints = 0;
      if (userDoc.exists) {
        currentPoints = (userDoc.data()?['points'] ?? 0) as int;
      }

      // Calculate new points
      final newPoints = currentPoints + change;

      // Make sure points don't go negative
      final finalPoints = newPoints < 0 ? 0 : newPoints;

      // Update Firebase
      await _firestore.collection('users').doc(user.uid).update({
        'points': finalPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _totalPoints = finalPoints;
      });

      // Update leaderboard service
      if (mounted) {
        context.read<LeaderboardService>().loadLeaderboard();
      }
    } catch (e) {
      debugPrint('Error adjusting points: $e');
    }
  }

  // Calculate usage for a specific week
  Future<void> _calculateWeekUsage(int week) async {
    final count1Key = 'week${week}count1';
    final count2Key = 'week${week}count2';

    final count1 = double.tryParse(_weekCounts[count1Key] ?? '') ?? 0;
    final count2 = double.tryParse(_weekCounts[count2Key] ?? '') ?? 0;

    if (count1 > 0 && count2 > 0 && count2 >= count1) {
      final kwh = count2 - count1;
      await _saveWeeklyKwh(week, kwh);

      // Send budget status notification
      final allocated = _getAllocatedBudgets()['week$week']!;
      await _weeklyNotificationService.checkBudgetStatus(
        week: week,
        actualKwh: kwh,
        allocatedKwh: allocated,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Week $week: ${kwh.toStringAsFixed(1)} kWh calculated!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter valid meter readings (count2 must be ≥ count1)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Check if week passed budget
  bool _isWeekPassed(int week) {
    final actualUsage = (_budgetData['week$week'] ?? 0).toDouble();
    final allocated = _getAllocatedBudgets()['week$week']!;
    return actualUsage > 0 && actualUsage <= allocated;
  }

  // Calculate rewards
  Map<String, int> _calculateRewards() {
    int points = 0;
    int streak = 0;
    final currentWeek = _getCurrentWeek();

    // Calculate streak: count consecutive weeks with good budget up to last completed week
    for (int i = 1; i < currentWeek; i++) {
      final actualUsage = (_budgetData['week$i'] ?? 0).toDouble();
      final allocated = _getAllocatedBudgets()['week$i']!;

      // Check if this week has data and is within budget
      if (actualUsage > 0 && actualUsage <= allocated) {
        streak++;
        points += 10; // Award points for passing weeks
      } else if (actualUsage > 0) {
        // Week has data but exceeded budget - break streak
        streak = 0;
      }
      // If actualUsage is 0, the week hasn't been recorded yet, don't break streak
    }

    return {'points': points, 'streak': streak};
  }

  // Show energy saving tips dialog
  void _showEnergySavingTips() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Energy Saving Tips',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Tips List
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTipItem(
                        '1. Switch to LED Bulbs',
                        'Replace incandescent bulbs with LED lights. They use 75% less energy and last 25 times longer.',
                        Icons.lightbulb,
                        Colors.amber,
                      ),
                      _buildTipItem(
                        '2. Unplug Idle Devices',
                        'Unplug chargers and devices when not in use. They consume power even in standby mode.',
                        Icons.power_off,
                        Colors.red,
                      ),
                      _buildTipItem(
                        '3. Use Natural Light',
                        'Open curtains during the day to reduce artificial lighting needs.',
                        Icons.wb_sunny,
                        Colors.orange,
                      ),
                      _buildTipItem(
                        '4. Optimize Air Conditioning',
                        'Set AC to 24-26°C and use fans. Clean filters monthly for efficiency.',
                        Icons.ac_unit,
                        Colors.blue,
                      ),
                      _buildTipItem(
                        '5. Maintain Refrigerator',
                        'Keep refrigerator at optimal temperature (3-5°C). Avoid opening door frequently.',
                        Icons.kitchen,
                        Colors.cyan,
                      ),
                      _buildTipItem(
                        '6. Use Energy-Efficient Appliances',
                        'Choose appliances with high energy star ratings when replacing old ones.',
                        Icons.star,
                        Colors.green,
                      ),
                      _buildTipItem(
                        '7. Wash Clothes Efficiently',
                        'Use cold water for washing and full loads. Air dry when possible.',
                        Icons.local_laundry_service,
                        Colors.indigo,
                      ),
                      _buildTipItem(
                        '8. Seal Air Leaks',
                        'Seal gaps around doors and windows to reduce AC/heating usage.',
                        Icons.door_front_door,
                        Colors.brown,
                      ),
                      _buildTipItem(
                        '9. Use Power Strips',
                        'Connect multiple devices to a power strip and turn it off when not needed.',
                        Icons.power,
                        Colors.purple,
                      ),
                      _buildTipItem(
                        '10. Cook Smart',
                        'Use pressure cookers, keep lids on pots, and match pan size to burner size.',
                        Icons.soup_kitchen,
                        Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getUnreadNotificationsCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final notificationService = NotificationService();
      return await notificationService.getUnreadNotificationsCount(user.uid);
    } catch (e) {
      debugPrint('Error getting unread notifications count: $e');
      return 0;
    }
  }

  Widget _buildNotificationButton() {
    return FutureBuilder<int>(
      future: _getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data! > 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).pushNamed('/new-notifications');
              },
              tooltip: 'Notifications',
            ),
            if (hasUnread)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    snapshot.data! > 9 ? '9+' : '${snapshot.data}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Check if budget exists
    if (_budgetData.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Electricity Monitor'),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Budget Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please create a budget for ${_getBudgetDocId()} to start tracking.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    // Navigate to budget creation screen and wait for result
                    final result = await Navigator.pushNamed(
                      context,
                      '/new-budget-plan-selection',
                    );

                    // If budget was created, reload the data
                    if (result != null && mounted) {
                      await _loadBudgetData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Create Budget',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentWeek = _getCurrentWeek();
    final rewards = _calculateRewards();
    final monthlyKwh = (_budgetData['kwh'] ?? 120).toDouble();
    final monthlyPrice = (_budgetData['price'] ?? 4500).toDouble();
    final budgetPlanName = _budgetData['budget_plan_name'] ?? 'Economy Plan';

    // Calculate total actual usage
    double totalActualUsage = 0;
    for (int i = 1; i <= 4; i++) {
      totalActualUsage += (_budgetData['week$i'] ?? 0).toDouble();
    }

    // Determine if within budget
    final isWithinBudget =
        totalActualUsage > 0 && totalActualUsage <= monthlyKwh;
    final hasUsageData = totalActualUsage > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Electricity Monitor'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          _buildNotificationButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Monthly Budget Overview Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Budget',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                budgetPlanName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Energy Budget',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${monthlyKwh.toStringAsFixed(0)} kWh',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price Budget',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'LKR ${monthlyPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Monthly Budget Status Message
            if (hasUsageData)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isWithinBudget
                          ? [Colors.green.shade400, Colors.teal.shade500]
                          : [Colors.red.shade400, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isWithinBudget ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isWithinBudget
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isWithinBudget
                            ? 'You Are Within Budget!'
                            : 'You Exceeded The Budget!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${totalActualUsage.toStringAsFixed(1)} kWh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' / ${monthlyKwh.toStringAsFixed(0)} kWh',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isWithinBudget
                            ? 'Great job! Keep up the good work!'
                            : 'Try to reduce your usage next time.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Add tips button only when budget is exceeded
                      if (!isWithinBudget) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showEnergySavingTips,
                          icon: const Icon(Icons.lightbulb_outline, size: 20),
                          label: const Text(
                            'Get Energy Saving Tips',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Rewards Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.orange.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.stars,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Points',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$_totalPoints',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.teal.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Streak',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${rewards['streak']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Badges Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Badges',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (int week = 1; week <= 4; week++) _buildBadge(week),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Week Slider Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weekly Meter Readings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Week ${_currentSlide + 1}/4',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Week Slider
            SizedBox(
              height: 550,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentSlide = index;
                  });
                },
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildWeekSlide(index + 1, currentWeek),
                  );
                },
              ),
            ),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        child: _buildQuickActionCard(
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
                        child: _buildQuickActionCard(
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
                        child: _buildQuickActionCard(
                          icon: Icons.analytics,
                          label: 'Analysis',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pushNamed(context, '/budget-analysis');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
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
                        child: _buildQuickActionCard(
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
                        child: _buildQuickActionCard(
                          icon: Icons.energy_savings_leaf,
                          label: 'Energy Tips',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.pushNamed(context, '/energy-saving-tips');
                          },
                        ),
                      ),
                    ],
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

  Widget _buildQuickActionCard({
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

  Widget _buildBadge(int week) {
    final passed = _isWeekPassed(week);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: passed
                ? LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  )
                : null,
            color: passed ? null : Colors.grey.shade200,
            boxShadow: passed
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.emoji_events,
            color: passed ? Colors.white : Colors.grey.shade400,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Week $week',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: passed ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSlide(int week, int currentWeek) {
    final count1Key = 'week${week}count1';
    final count2Key = 'week${week}count2';

    // Use stored controllers instead of creating new ones
    final count1Controller = _controllers[count1Key]!;
    final count2Controller = _controllers[count2Key]!;

    final kwh = (_budgetData['week$week'] ?? 0).toDouble();
    final allocated = _getAllocatedBudgets()['week$week']!;
    final passed = _isWeekPassed(week);
    final isCurrent = week == currentWeek;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isCurrent
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week $week',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      isCurrent
                          ? '(Current Week)'
                          : 'Days ${(week - 1) * 7 + 1}-${week == 4 ? 'End' : week * 7}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                if (passed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Meter Reading 1
            const Text(
              'Meter Reading 1 (Start)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: count1Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter starting meter reading',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _weekCounts[count1Key] = value;
                });
                _saveMeterCounts();
              },
            ),
            const SizedBox(height: 16),

            // Meter Reading 2
            const Text(
              'Meter Reading 2 (End)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: count2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter ending meter reading',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _weekCounts[count2Key] = value;
                });
                _saveMeterCounts();
              },
            ),
            const SizedBox(height: 20),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _calculateWeekUsage(week),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Calculate Usage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Usage Summary
            if (kwh > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Allocated Budget:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${allocated.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Actual Usage:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${kwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: passed
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            passed ? '✓ Passed' : '✗ Over Budget',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: passed
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
