import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id; // Document ID in format "year-month" (e.g., "2025-10")
  final String userId;
  final String budgetPlanName;
  final int year;
  final int month;
  final double kwh; // Total monthly kWh limit
  final double price; // Total monthly price limit
  final double week1; // Week 1 kWh usage
  final double week2; // Week 2 kWh usage
  final double week3; // Week 3 kWh usage
  final double week4; // Week 4 kWh usage
  final DateTime createdAt;
  final DateTime? updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.budgetPlanName,
    required this.year,
    required this.month,
    required this.kwh,
    required this.price,
    this.week1 = 0.0,
    this.week2 = 0.0,
    this.week3 = 0.0,
    this.week4 = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  // Get document ID in format "year-month"
  static String generateDocId(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime createdDateTime;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      createdDateTime = (map['createdAt'] as Timestamp).toDate();
    } else {
      createdDateTime = DateTime.now();
    }

    DateTime? updatedDateTime;
    if (map['updatedAt'] != null && map['updatedAt'] is Timestamp) {
      updatedDateTime = (map['updatedAt'] as Timestamp).toDate();
    }

    return BudgetModel(
      id: id,
      userId: map['user_id'] ?? '',
      budgetPlanName: map['budget_plan_name'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      kwh: (map['kwh'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      week1: (map['week1'] ?? 0).toDouble(),
      week2: (map['week2'] ?? 0).toDouble(),
      week3: (map['week3'] ?? 0).toDouble(),
      week4: (map['week4'] ?? 0).toDouble(),
      createdAt: createdDateTime,
      updatedAt: updatedDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'budget_plan_name': budgetPlanName,
      'year': year,
      'month': month,
      'kwh': kwh,
      'price': price,
      'week1': week1,
      'week2': week2,
      'week3': week3,
      'week4': week4,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Get total used kWh from all weeks
  double get totalUsedKwh => week1 + week2 + week3 + week4;

  // Get remaining kWh
  double get remainingKwh => kwh - totalUsedKwh;

  // Get usage percentage
  double get usagePercentage => kwh > 0 ? (totalUsedKwh / kwh) : 0.0;

  // Check if budget is expired (after the end of the month)
  bool get isExpired {
    final now = DateTime.now();
    final budgetEndDate = DateTime(year, month + 1, 0); // Last day of the month
    return now.isAfter(budgetEndDate);
  }

  // Check if this is the current month's budget
  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? budgetPlanName,
    int? year,
    int? month,
    double? kwh,
    double? price,
    double? week1,
    double? week2,
    double? week3,
    double? week4,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      budgetPlanName: budgetPlanName ?? this.budgetPlanName,
      year: year ?? this.year,
      month: month ?? this.month,
      kwh: kwh ?? this.kwh,
      price: price ?? this.price,
      week1: week1 ?? this.week1,
      week2: week2 ?? this.week2,
      week3: week3 ?? this.week3,
      week4: week4 ?? this.week4,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BudgetModel{id: $id, userId: $userId, budgetPlanName: $budgetPlanName, year: $year, month: $month, kwh: $kwh, totalUsed: $totalUsedKwh}';
  }
}