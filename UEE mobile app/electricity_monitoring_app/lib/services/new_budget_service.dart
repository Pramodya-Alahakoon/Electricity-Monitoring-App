import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/new_budget_model.dart';
import 'weekly_budget_notification_service.dart';

class NewBudgetService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeeklyBudgetNotificationService _notificationService =
      WeeklyBudgetNotificationService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;

  // Get current month's budget
  BudgetModel? get currentBudget {
    final now = DateTime.now();
    final currentMonthId = BudgetModel.generateDocId(now.year, now.month);

    try {
      return _budgets.firstWhere((budget) => budget.id == currentMonthId);
    } catch (e) {
      return null;
    }
  }

  // Check if current month has a budget
  bool get hasCurrentBudget => currentBudget != null;

  // Get previous budgets (all except current month)
  List<BudgetModel> get previousBudgets {
    final now = DateTime.now();
    final currentMonthId = BudgetModel.generateDocId(now.year, now.month);

    return _budgets.where((budget) => budget.id != currentMonthId).toList()
      ..sort((a, b) {
        // Sort by year and month descending
        if (a.year != b.year) {
          return b.year.compareTo(a.year);
        }
        return b.month.compareTo(a.month);
      });
  }

  // Initialize and load budgets
  Future<void> fetchBudgets() async {
    if (_auth.currentUser == null) {
      debugPrint('No authenticated user');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('Fetching budgets for user: $userId');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      _budgets = snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
          .toList();

      debugPrint('Loaded ${_budgets.length} budgets');
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      _budgets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new monthly budget
  Future<bool> createMonthlyBudget({
    required String budgetPlanName,
    required double kwh,
    required double price,
  }) async {
    if (_auth.currentUser == null) {
      debugPrint('No authenticated user');
      return false;
    }

    try {
      final userId = _auth.currentUser!.uid;
      final now = DateTime.now();
      final docId = BudgetModel.generateDocId(now.year, now.month);

      // Check if budget already exists for current month
      final existingDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(docId)
          .get();

      if (existingDoc.exists) {
        debugPrint('Budget already exists for current month');
        throw Exception('A budget already exists for this month');
      }

      // Create new budget document
      final budgetData = {
        'user_id': userId,
        'budget_plan_name': budgetPlanName,
        'year': now.year,
        'month': now.month,
        'kwh': kwh,
        'price': price,
        'week1': 0.0,
        'week2': 0.0,
        'week3': 0.0,
        'week4': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(docId)
          .set(budgetData);

      debugPrint('Budget created successfully: $docId');

      // Reload budgets
      await fetchBudgets();

      return true;
    } catch (e) {
      debugPrint('Error creating budget: $e');
      return false;
    }
  }

  // Update weekly kWh usage
  Future<bool> updateWeeklyKwh({
    required int weekNumber,
    required double kwh,
  }) async {
    if (_auth.currentUser == null) {
      debugPrint('No authenticated user');
      return false;
    }

    if (weekNumber < 1 || weekNumber > 4) {
      debugPrint('Invalid week number: $weekNumber');
      return false;
    }

    try {
      final userId = _auth.currentUser!.uid;
      final currentBudget = this.currentBudget;
      if (currentBudget == null) {
        debugPrint('No current budget found');
        return false;
      }

      // Get old week value to check previous status
      double oldKwh = 0;
      switch (weekNumber) {
        case 1:
          oldKwh = currentBudget.week1;
          break;
        case 2:
          oldKwh = currentBudget.week2;
          break;
        case 3:
          oldKwh = currentBudget.week3;
          break;
        case 4:
          oldKwh = currentBudget.week4;
          break;
      }

      // Calculate allocated budget for this week
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysInWeeks = [7, 7, 7, daysInMonth - 21];
      final totalDays = daysInWeeks.reduce((a, b) => a + b);
      final allocated =
          currentBudget.kwh * daysInWeeks[weekNumber - 1] / totalDays;

      // Check if there was previous data
      final hadPreviousData = oldKwh > 0;

      // Check old status (was it within budget?)
      final wasWithinBudget = hadPreviousData && oldKwh <= allocated;

      // Check new status (is it within budget?)
      final isWithinBudget = kwh > 0 && kwh <= allocated;

      // Calculate point change
      int pointChange = 0;

      if (!hadPreviousData && isWithinBudget) {
        // First time adding data and it's within budget: ADD 10 points
        pointChange = 10;
      } else if (!hadPreviousData && !isWithinBudget) {
        // First time adding data and it's over budget: No points
        pointChange = 0;
      } else if (hadPreviousData && wasWithinBudget && !isWithinBudget) {
        // Had data that was within budget, now it's over budget: SUBTRACT 10 points
        pointChange = -10;
      } else if (hadPreviousData && !wasWithinBudget && isWithinBudget) {
        // Had data that was over budget, now it's within budget: ADD 10 points
        pointChange = 10;
      }
      // If both were within budget or both over budget, no change

      // Update the specific week field
      final weekField = 'week$weekNumber';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(currentBudget.id)
          .update({weekField: kwh, 'updatedAt': FieldValue.serverTimestamp()});

      debugPrint('Week $weekNumber updated to $kwh kWh');

      // Update points if there's a change
      if (pointChange != 0) {
        await _adjustPoints(userId, pointChange);
      }

      // Send budget status notification
      await _notificationService.checkBudgetStatus(
        week: weekNumber,
        actualKwh: kwh,
        allocatedKwh: allocated,
      );

      // Update local data
      final updatedBudget = currentBudget.copyWith(
        week1: weekNumber == 1 ? kwh : currentBudget.week1,
        week2: weekNumber == 2 ? kwh : currentBudget.week2,
        week3: weekNumber == 3 ? kwh : currentBudget.week3,
        week4: weekNumber == 4 ? kwh : currentBudget.week4,
        updatedAt: DateTime.now(),
      );

      final index = _budgets.indexWhere((b) => b.id == currentBudget.id);
      if (index != -1) {
        _budgets[index] = updatedBudget;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating weekly kWh: $e');
      return false;
    }
  }

  // Adjust points by adding or subtracting
  Future<void> _adjustPoints(String userId, int change) async {
    try {
      // Get current points from Firebase
      final userDoc = await _firestore.collection('users').doc(userId).get();
      int currentPoints = 0;
      if (userDoc.exists) {
        currentPoints = (userDoc.data()?['points'] ?? 0) as int;
      }

      // Calculate new points
      final newPoints = currentPoints + change;

      // Make sure points don't go negative
      final finalPoints = newPoints < 0 ? 0 : newPoints;

      // Update Firebase
      await _firestore.collection('users').doc(userId).update({
        'points': finalPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Points adjusted by $change. New total: $finalPoints');
    } catch (e) {
      debugPrint('Error adjusting points: $e');
    }
  }

  // Change budget plan (update kwh and price)
  Future<bool> changeBudgetPlan({
    required String budgetPlanName,
    required double kwh,
    required double price,
  }) async {
    if (_auth.currentUser == null) {
      debugPrint('No authenticated user');
      return false;
    }

    try {
      final userId = _auth.currentUser!.uid;
      final currentBudget = this.currentBudget;
      if (currentBudget == null) {
        debugPrint('No current budget found');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(currentBudget.id)
          .update({
            'budget_plan_name': budgetPlanName,
            'kwh': kwh,
            'price': price,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('Budget plan changed to $budgetPlanName');

      // Reload budgets
      await fetchBudgets();

      return true;
    } catch (e) {
      debugPrint('Error changing budget plan: $e');
      return false;
    }
  }

  // Delete current month's budget
  Future<bool> deleteCurrentBudget() async {
    if (_auth.currentUser == null) {
      debugPrint('No authenticated user');
      return false;
    }

    try {
      final userId = _auth.currentUser!.uid;
      final currentBudget = this.currentBudget;
      if (currentBudget == null) {
        debugPrint('No current budget to delete');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(currentBudget.id)
          .delete();

      debugPrint('Budget deleted: ${currentBudget.id}');

      // Remove from local list
      _budgets.removeWhere((b) => b.id == currentBudget.id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      return false;
    }
  }

  // Get budget by document ID
  BudgetModel? getBudgetById(String id) {
    try {
      return _budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  // Stream current budget for real-time updates
  Stream<BudgetModel?> getCurrentBudgetStream() {
    if (_auth.currentUser == null) {
      return Stream.value(null);
    }

    final userId = _auth.currentUser!.uid;
    final now = DateTime.now();
    final docId = BudgetModel.generateDocId(now.year, now.month);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return BudgetModel.fromMap(
            snapshot.data() as Map<String, dynamic>,
            snapshot.id,
          );
        });
  }

  // Check if budget exists for specific month
  Future<bool> hasBudgetForMonth(int year, int month) async {
    if (_auth.currentUser == null) return false;

    try {
      final userId = _auth.currentUser!.uid;
      final docId = BudgetModel.generateDocId(year, month);
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(docId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking budget existence: $e');
      return false;
    }
  }

  // Get budget statistics
  Map<String, dynamic> getBudgetStatistics() {
    if (_budgets.isEmpty) {
      return {
        'totalBudgets': 0,
        'totalKwhUsed': 0.0,
        'averageUsage': 0.0,
        'monthsOverBudget': 0,
      };
    }

    double totalKwhUsed = 0.0;
    int monthsOverBudget = 0;

    for (var budget in _budgets) {
      totalKwhUsed += budget.totalUsedKwh;
      if (budget.usagePercentage > 1.0) {
        monthsOverBudget++;
      }
    }

    return {
      'totalBudgets': _budgets.length,
      'totalKwhUsed': totalKwhUsed,
      'averageUsage': totalKwhUsed / _budgets.length,
      'monthsOverBudget': monthsOverBudget,
    };
  }

  // Clean up expired budgets (optional - call this periodically)
  Future<void> cleanupExpiredBudgets() async {
    if (_auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .where('year', isLessThan: sixMonthsAgo.year)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} expired budgets');

      // Reload budgets
      await fetchBudgets();
    } catch (e) {
      debugPrint('Error cleaning up expired budgets: $e');
    }
  }

  // Reset weekly data for current budget
  Future<bool> resetWeeklyData() async {
    if (_auth.currentUser == null) return false;

    try {
      final userId = _auth.currentUser!.uid;
      final currentBudget = this.currentBudget;
      if (currentBudget == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(currentBudget.id)
          .update({
            'week1': 0.0,
            'week2': 0.0,
            'week3': 0.0,
            'week4': 0.0,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('Weekly data reset successfully');

      // Reload budgets
      await fetchBudgets();

      return true;
    } catch (e) {
      debugPrint('Error resetting weekly data: $e');
      return false;
    }
  }

  // Get budget usage summary
  Map<String, dynamic> getCurrentBudgetSummary() {
    final budget = currentBudget;

    if (budget == null) {
      return {'exists': false, 'message': 'No budget for current month'};
    }

    final percentUsed = budget.usagePercentage * 100;
    String status;
    Color statusColor;

    if (percentUsed >= 100) {
      status = 'Over Budget';
      statusColor = const Color(0xFFE53935);
    } else if (percentUsed >= 80) {
      status = 'Warning';
      statusColor = const Color(0xFFFFA726);
    } else if (percentUsed >= 50) {
      status = 'On Track';
      statusColor = const Color(0xFF42A5F5);
    } else {
      status = 'Excellent';
      statusColor = const Color(0xFF66BB6A);
    }

    return {
      'exists': true,
      'budgetLimit': budget.kwh,
      'totalUsed': budget.totalUsedKwh,
      'remaining': budget.remainingKwh,
      'percentUsed': percentUsed,
      'status': status,
      'statusColor': statusColor,
      'isOverBudget': percentUsed >= 100,
    };
  }

  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
}
