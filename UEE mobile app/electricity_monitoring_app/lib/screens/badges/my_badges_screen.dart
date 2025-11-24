import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class MyBadgesScreen extends StatefulWidget {
  static const routeName = '/my-badges';

  const MyBadgesScreen({super.key});

  @override
  State<MyBadgesScreen> createState() => _MyBadgesScreenState();
}

class _MyBadgesScreenState extends State<MyBadgesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic> _budgetData = {};
  int _totalPoints = 0;
  int _currentStreak = 0;
  List<Map<String, dynamic>> _availableMonths = [];
  String? _selectedMonthId;

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  // Load all available months
  Future<void> _loadAvailableMonths() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all budget documents
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      List<Map<String, dynamic>> months = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        months.add({
          'id': doc.id,
          'year': data['year'] ?? 0,
          'month': data['month'] ?? 0,
          'data': data,
        });
      }

      setState(() {
        _availableMonths = months;
        // Select current month by default
        if (months.isNotEmpty) {
          final now = DateTime.now();
          final currentMonthId =
              '${now.year}-${now.month.toString().padLeft(2, '0')}';

          // Check if current month exists in the list
          final currentExists = months.any((m) => m['id'] == currentMonthId);
          _selectedMonthId = currentExists
              ? currentMonthId
              : months.first['id'];
        }
      });

      if (_selectedMonthId != null) {
        await _loadMonthlyData(_selectedMonthId!);
      }
    } catch (e) {
      debugPrint('Error loading months: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Map<String, int> _getDaysInWeeks(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return {'week1': 7, 'week2': 7, 'week3': 7, 'week4': daysInMonth - 21};
  }

  Map<String, double> _getAllocatedBudgets() {
    final monthData = _availableMonths.firstWhere(
      (m) => m['id'] == _selectedMonthId,
      orElse: () => {},
    );

    if (monthData.isEmpty) return {};

    final days = _getDaysInWeeks(monthData['year'], monthData['month']);
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

  bool _isWeekPassed(int week) {
    final actualUsage = (_budgetData['week$week'] ?? 0).toDouble();
    final allocated = _getAllocatedBudgets()['week$week'] ?? 0;
    return actualUsage > 0 && actualUsage <= allocated;
  }

  int _calculateStreak() {
    int streak = 0;
    final currentWeek = _getCurrentWeek();

    for (int i = 1; i < currentWeek; i++) {
      final actualUsage = (_budgetData['week$i'] ?? 0).toDouble();
      final allocated = _getAllocatedBudgets()['week$i'] ?? 0;

      if (actualUsage > 0 && actualUsage <= allocated) {
        streak++;
      } else if (actualUsage > 0) {
        streak = 0;
      }
    }
    return streak;
  }

  int _getCurrentWeek() {
    final today = DateTime.now();

    // Check if selected month is current month
    final now = DateTime.now();
    final currentMonthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (_selectedMonthId != currentMonthId) {
      // For past months, return 5 (all weeks completed)
      return 5;
    }

    final dayOfMonth = today.day;
    if (dayOfMonth <= 7) return 1;
    if (dayOfMonth <= 14) return 2;
    if (dayOfMonth <= 21) return 3;
    return 4;
  }

  Future<void> _loadMonthlyData(String budgetDocId) async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetDocId)
          .get();

      if (doc.exists) {
        _budgetData = Map<String, dynamic>.from(doc.data() ?? {});
      } else {
        _budgetData = {};
      }

      // Load current points from user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _totalPoints = (userDoc.data()?['points'] ?? 0) as int;
      }

      _currentStreak = _calculateStreak();
    } catch (e) {
      debugPrint('Error loading monthly data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Badges'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableMonths.isEmpty
          ? _buildNoBudgetView()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Simple Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_getSelectedMonthName()} Badges',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Simple Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.amber[400],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_totalPoints',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Total Points',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            color: Colors.orange[600],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_currentStreak',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Week Streak',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Month Selector
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildMonthSelector(),
                  ),

                  // Weekly Badges
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Badges',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWeeklyBadgesGrid(),
                      ],
                    ),
                  ),

                  // Simple How to Earn
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'How to Earn Badges',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSimpleItem('Stay within weekly budget'),
                            _buildSimpleItem('Earn 10 points per week'),
                            _buildSimpleItem('Build your streak'),
                            _buildSimpleItem('Collect all badges'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildNoBudgetView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Budget Data Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget to start earning badges',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getSelectedMonthName() {
    if (_selectedMonthId == null || _availableMonths.isEmpty) {
      return DateTime.now().month.toString();
    }

    final selected = _availableMonths.firstWhere(
      (m) => m['id'] == _selectedMonthId,
      orElse: () => _availableMonths.first,
    );

    return '${_getMonthName(selected['month'])} ${selected['year']}';
  }

  Widget _buildMonthSelector() {
    if (_availableMonths.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final currentMonthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMonthId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _availableMonths.map((monthData) {
                final monthName = DateFormat(
                  'MMMM yyyy',
                ).format(DateTime(monthData['year'], monthData['month']));
                final isCurrent = monthData['id'] == currentMonthId;

                return DropdownMenuItem<String>(
                  value: monthData['id'] as String,
                  child: Row(
                    children: [
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      if (isCurrent) const SizedBox(width: 8),
                      Text(monthName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonthId = value;
                  });
                  _loadMonthlyData(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3, // Increased from 1.2 to fix overflow
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final week = index + 1;
        return _buildBadgeCard(week);
      },
    );
  }

  Widget _buildBadgeCard(int week) {
    final passed = _isWeekPassed(week);
    final currentWeek = _getCurrentWeek();
    final isFutureWeek = week > currentWeek;
    final actualUsage = (_budgetData['week$week'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _showBadgeDetails(week),
      child: Card(
        color: passed
            ? Colors.green[400]
            : isFutureWeek
            ? Colors.grey[200]
            : Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced from 12
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color: passed
                    ? Colors.white
                    : isFutureWeek
                    ? Colors.grey[400]
                    : Colors.red[300],
                size: 36, // Reduced from 40
              ),
              const SizedBox(height: 6), // Reduced from 8
              Text(
                'Week $week',
                style: TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4), // Reduced from 6
              Flexible(
                child: Text(
                  passed
                      ? '✓ Achieved'
                      : isFutureWeek
                      ? 'Upcoming'
                      : actualUsage > 0
                      ? '✗ Over'
                      : 'Not Started',
                  style: TextStyle(
                    fontSize: 10, // Reduced from 11
                    fontWeight: FontWeight.w600,
                    color: passed ? Colors.white : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (passed) ...[
                const SizedBox(height: 4), // Reduced from 6
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+10 pts',
                    style: TextStyle(
                      fontSize: 10, // Reduced from 11
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(int week) {
    final passed = _isWeekPassed(week);
    final currentWeek = _getCurrentWeek();
    final isFutureWeek = week > currentWeek;
    final actualUsage = (_budgetData['week$week'] ?? 0).toDouble();
    final allocated = _getAllocatedBudgets()['week$week'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Week $week Badge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFutureWeek) ...[
              const Text('This week hasn\'t started yet.'),
            ] else if (actualUsage == 0) ...[
              const Text('No meter readings recorded yet.'),
              const SizedBox(height: 8),
              Text('Budget: ${allocated.toStringAsFixed(1)} kWh'),
            ] else ...[
              Text(
                'Status: ${passed ? "✓ Achieved" : "✗ Over Budget"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text('Budget: ${allocated.toStringAsFixed(1)} kWh'),
              Text('Usage: ${actualUsage.toStringAsFixed(1)} kWh'),
              if (passed) ...[
                const SizedBox(height: 12),
                const Text('🎉 You earned 10 points!'),
              ],
            ],
          ],
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

  Widget _buildSimpleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue[700], size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
