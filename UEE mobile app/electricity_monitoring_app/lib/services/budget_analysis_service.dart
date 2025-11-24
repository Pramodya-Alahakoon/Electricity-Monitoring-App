import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/new_budget_model.dart';

class MonthComparison {
  final BudgetModel currentMonth;
  final BudgetModel? previousMonth;
  final double usageChange; // Percentage change
  final double avgWeeklyChange;
  final String trend; // 'improving', 'declining', 'stable'
  final List<String> insights;
  final List<String> predictions;

  MonthComparison({
    required this.currentMonth,
    this.previousMonth,
    required this.usageChange,
    required this.avgWeeklyChange,
    required this.trend,
    required this.insights,
    required this.predictions,
  });
}

class BudgetAnalysisService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  MonthComparison? _comparison;

  bool get isLoading => _isLoading;
  MonthComparison? get comparison => _comparison;

  // Get budget by year and month
  Future<BudgetModel?> getBudgetByYearMonth(int year, int month) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docId = BudgetModel.generateDocId(year, month);
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(docId)
          .get();

      if (doc.exists) {
        return BudgetModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting budget: $e');
      return null;
    }
  }

  // Compare current month with previous month
  Future<MonthComparison?> compareMonths(BudgetModel currentMonth) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get previous month
      int prevYear = currentMonth.year;
      int prevMonth = currentMonth.month - 1;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear--;
      }

      final previousMonth = await getBudgetByYearMonth(prevYear, prevMonth);

      // Calculate comparison metrics
      double usageChange = 0;
      double avgWeeklyChange = 0;
      String trend = 'stable';

      if (previousMonth != null) {
        final currentTotal = currentMonth.totalUsedKwh;
        final previousTotal = previousMonth.totalUsedKwh;

        if (previousTotal > 0) {
          usageChange = ((currentTotal - previousTotal) / previousTotal) * 100;
        }

        // Calculate average weekly change
        final currentWeeks = [
          currentMonth.week1,
          currentMonth.week2,
          currentMonth.week3,
          currentMonth.week4,
        ];
        final previousWeeks = [
          previousMonth.week1,
          previousMonth.week2,
          previousMonth.week3,
          previousMonth.week4,
        ];

        double totalWeeklyChange = 0;
        int validWeeks = 0;
        for (int i = 0; i < 4; i++) {
          if (previousWeeks[i] > 0 && currentWeeks[i] > 0) {
            totalWeeklyChange += currentWeeks[i] - previousWeeks[i];
            validWeeks++;
          }
        }
        if (validWeeks > 0) {
          avgWeeklyChange = totalWeeklyChange / validWeeks;
        }

        // Determine trend
        if (usageChange < -5) {
          trend = 'improving';
        } else if (usageChange > 5) {
          trend = 'declining';
        }
      }

      // Generate insights
      final insights = _generateInsights(currentMonth, previousMonth);

      // Generate predictions
      final predictions = _generatePredictions(currentMonth, previousMonth);

      _comparison = MonthComparison(
        currentMonth: currentMonth,
        previousMonth: previousMonth,
        usageChange: usageChange,
        avgWeeklyChange: avgWeeklyChange,
        trend: trend,
        insights: insights,
        predictions: predictions,
      );

      _isLoading = false;
      notifyListeners();

      return _comparison;
    } catch (e) {
      debugPrint('Error comparing months: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Generate insights based on data
  List<String> _generateInsights(
    BudgetModel currentMonth,
    BudgetModel? previousMonth,
  ) {
    List<String> insights = [];

    // Current month insights
    if (currentMonth.usagePercentage > 1.0) {
      insights.add(
        'You exceeded your budget by ${((currentMonth.usagePercentage - 1) * 100).toStringAsFixed(1)}%. Consider reducing usage.',
      );
    } else if (currentMonth.usagePercentage > 0.8) {
      insights.add(
        'You\'re at ${(currentMonth.usagePercentage * 100).toStringAsFixed(1)}% of your budget. Monitor usage carefully.',
      );
    } else if (currentMonth.usagePercentage > 0) {
      insights.add(
        'Good job! You\'re using only ${(currentMonth.usagePercentage * 100).toStringAsFixed(1)}% of your budget.',
      );
    }

    // Week analysis
    final weeks = [
      currentMonth.week1,
      currentMonth.week2,
      currentMonth.week3,
      currentMonth.week4,
    ];
    final maxWeekIndex = weeks.indexOf(weeks.reduce((a, b) => a > b ? a : b));
    final minWeekIndex = weeks.indexOf(weeks.reduce((a, b) => a < b ? a : b));

    if (weeks[maxWeekIndex] > 0) {
      insights.add(
        'Week ${maxWeekIndex + 1} had the highest usage (${weeks[maxWeekIndex].toStringAsFixed(1)} kWh).',
      );
    }

    if (weeks[minWeekIndex] > 0 && weeks[minWeekIndex] != weeks[maxWeekIndex]) {
      insights.add(
        'Week ${minWeekIndex + 1} had the lowest usage (${weeks[minWeekIndex].toStringAsFixed(1)} kWh). Great conservation!',
      );
    }

    // Comparison insights
    if (previousMonth != null) {
      final currentTotal = currentMonth.totalUsedKwh;
      final previousTotal = previousMonth.totalUsedKwh;

      if (currentTotal > 0 && previousTotal > 0) {
        final change = ((currentTotal - previousTotal) / previousTotal) * 100;
        if (change < -10) {
          insights.add(
            'Excellent! Usage decreased by ${change.abs().toStringAsFixed(1)}% compared to last month.',
          );
        } else if (change > 10) {
          insights.add(
            'Usage increased by ${change.toStringAsFixed(1)}% compared to last month. Review your consumption patterns.',
          );
        }
      }

      // Budget adherence comparison
      if (currentMonth.usagePercentage < previousMonth.usagePercentage) {
        insights.add(
          'You\'re improving! Better budget adherence than last month.',
        );
      }
    }

    return insights;
  }

  // Generate predictions for next month
  List<String> _generatePredictions(
    BudgetModel currentMonth,
    BudgetModel? previousMonth,
  ) {
    List<String> predictions = [];

    // Calculate trend
    if (previousMonth != null) {
      final currentTotal = currentMonth.totalUsedKwh;
      final previousTotal = previousMonth.totalUsedKwh;

      if (currentTotal > 0 && previousTotal > 0) {
        final change = currentTotal - previousTotal;
        final predictedUsage = currentTotal + change;

        predictions.add(
          'Based on current trend, next month\'s usage may be around ${predictedUsage.toStringAsFixed(1)} kWh.',
        );

        // Recommendation based on prediction
        if (predictedUsage > currentMonth.kwh) {
          predictions.add(
            'This would exceed your current budget. Consider increasing your budget or reducing consumption.',
          );
        } else {
          predictions.add(
            'You should be within budget if the trend continues. Keep up the good work!',
          );
        }
      }
    }

    // Seasonal recommendations
    final month = currentMonth.month;
    if (month >= 12 || month <= 2) {
      predictions.add(
        'Winter months typically see higher usage due to heating. Plan accordingly.',
      );
    } else if (month >= 6 && month <= 8) {
      predictions.add(
        'Summer months may increase cooling costs. Monitor AC usage closely.',
      );
    }

    // Weekly pattern predictions
    final weeks = [
      currentMonth.week1,
      currentMonth.week2,
      currentMonth.week3,
      currentMonth.week4,
    ];

    if (weeks.where((w) => w > 0).length >= 3) {
      final avgWeekly =
          weeks.where((w) => w > 0).reduce((a, b) => a + b) /
          weeks.where((w) => w > 0).length;

      predictions.add(
        'Your average weekly usage is ${avgWeekly.toStringAsFixed(1)} kWh. Try to stay below this next month.',
      );
    }

    // Energy saving tips based on usage
    if (currentMonth.usagePercentage > 0.9) {
      predictions.add(
        'Tip: Use LED bulbs, unplug devices when not in use, and optimize AC temperature settings.',
      );
    }

    return predictions;
  }

  // Get all available budget months
  Future<List<Map<String, dynamic>>> getAvailableMonths() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'year': data['year'],
          'month': data['month'],
          'label': _getMonthLabel(data['year'], data['month']),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting available months: $e');
      return [];
    }
  }

  String _getMonthLabel(int year, int month) {
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
    return '${months[month - 1]} $year';
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStatistics(BudgetModel budget) {
    final weeks = [budget.week1, budget.week2, budget.week3, budget.week4];
    final activeWeeks = weeks.where((w) => w > 0).toList();

    if (activeWeeks.isEmpty) {
      return {
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
        'consistency': 0.0,
      };
    }

    final average = activeWeeks.reduce((a, b) => a + b) / activeWeeks.length;
    final highest = activeWeeks.reduce((a, b) => a > b ? a : b);
    final lowest = activeWeeks.reduce((a, b) => a < b ? a : b);

    // Calculate consistency (lower is better)
    double variance = 0;
    for (var week in activeWeeks) {
      variance += (week - average) * (week - average);
    }
    variance /= activeWeeks.length;
    final consistency = variance > 0 ? 100 / (1 + variance) : 100;

    return {
      'average': average,
      'highest': highest,
      'lowest': lowest,
      'consistency': consistency,
    };
  }
}
