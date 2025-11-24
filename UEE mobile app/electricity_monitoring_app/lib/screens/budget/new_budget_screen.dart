import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/new_budget_model.dart';
import '../../services/new_budget_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class NewBudgetScreen extends StatefulWidget {
  static const routeName = '/budget';
  final bool showBackButton;

  const NewBudgetScreen({super.key, this.showBackButton = true});

  @override
  State<NewBudgetScreen> createState() => _NewBudgetScreenState();
}

class _NewBudgetScreenState extends State<NewBudgetScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<NewBudgetService>(
        context,
        listen: false,
      ).fetchBudgets();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Budget Management',
        showBackButton: widget.showBackButton,
      ),
      body: _buildBody(),
      floatingActionButton: Consumer<NewBudgetService>(
        builder: (context, budgetService, child) {
          // Show create button only if no current budget exists
          if (!budgetService.hasCurrentBudget) {
            return FloatingActionButton.extended(
              backgroundColor: AppTheme.secondaryColor,
              onPressed: _showCreateBudgetDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Budget',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<NewBudgetService>(
      builder: (context, budgetService, child) {
        if (_isLoading || budgetService.isLoading) {
          return const LoadingIndicator(message: 'Loading budget data...');
        }

        final currentBudget = budgetService.currentBudget;
        final previousBudgets = budgetService.previousBudgets;

        return RefreshIndicator(
          onRefresh: _loadBudgets,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentBudget != null) ...[
                  _buildCurrentBudgetCard(currentBudget),
                  const SizedBox(height: 24),
                  _buildWeeklyDataSection(currentBudget),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(currentBudget),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildNoBudgetCard(),
                  const SizedBox(height: 24),
                ],
                if (previousBudgets.isNotEmpty) ...[
                  Text(
                    'Previous Budgets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...previousBudgets.map(
                    (budget) => _buildPreviousBudgetCard(budget),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoBudgetCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Budget for This Month',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a monthly budget to start tracking your electricity usage and manage your expenses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateBudgetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Monthly Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBudgetCard(BudgetModel budget) {
    final monthName = DateFormat(
      'MMMM',
    ).format(DateTime(budget.year, budget.month));
    final percentUsed = budget.usagePercentage;
    final isOverBudget = percentUsed > 1.0;

    Color statusColor;
    if (percentUsed >= 1.0) {
      statusColor = AppTheme.errorColor;
    } else if (percentUsed >= 0.8) {
      statusColor = AppTheme.warningColor;
    } else {
      statusColor = AppTheme.successColor;
    }

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$monthName ${budget.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.secondaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    budget.budgetPlanName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Budget Limit',
                    '${budget.kwh.toStringAsFixed(1)} kWh',
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Used',
                    '${budget.totalUsedKwh.toStringAsFixed(1)} kWh',
                    statusColor,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    isOverBudget ? 'Over' : 'Remaining',
                    '${budget.remainingKwh.abs().toStringAsFixed(1)} kWh',
                    isOverBudget ? AppTheme.errorColor : AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Budget Usage',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentUsed > 1 ? 1 : percentUsed,
              backgroundColor: Colors.grey.shade200,
              color: statusColor,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percentUsed * 100).toStringAsFixed(1)}% Used',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (isOverBudget)
                  Text(
                    'Budget Exceeded!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeleteBudget(budget),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyDataSection(BudgetModel budget) {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_view_week,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      Text(
                        'Track your weekly electricity usage',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildWeekCard(1, budget.week1, budget),
                _buildWeekCard(2, budget.week2, budget),
                _buildWeekCard(3, budget.week3, budget),
                _buildWeekCard(4, budget.week4, budget),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard(int weekNumber, double kwh, BudgetModel budget) {
    final hasData = kwh > 0;

    return GestureDetector(
      onTap: () => _showEditWeekDialog(weekNumber, kwh),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasData
                ? AppTheme.primaryColor.withOpacity(0.4)
                : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: hasData
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week $weekNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasData ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                Icon(
                  hasData ? Icons.edit : Icons.add_circle_outline,
                  size: 16,
                  color: hasData ? AppTheme.secondaryColor : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasData ? '${kwh.toStringAsFixed(1)} kWh' : 'Not set',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasData ? AppTheme.textColor : Colors.grey,
              ),
            ),
            Text(
              hasData ? 'Tap to edit' : 'Tap to add',
              style: TextStyle(fontSize: 10, color: AppTheme.lightTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BudgetModel budget) {
    final weeklyData = [
      {'week': 1, 'kwh': budget.week1},
      {'week': 2, 'kwh': budget.week2},
      {'week': 3, 'kwh': budget.week3},
      {'week': 4, 'kwh': budget.week4},
    ];

    final maxKwh = [
      budget.week1,
      budget.week2,
      budget.week3,
      budget.week4,
    ].reduce((a, b) => a > b ? a : b);
    final maxY = maxKwh > 0 ? maxKwh * 1.2 : 100.0;

    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Usage Chart',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      Text(
                        'Visual representation of weekly kWh',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          AppTheme.primaryColor.withOpacity(0.9),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Week ${group.x + 1}\n${rod.toY.toStringAsFixed(1)} kWh',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'W${value.toInt() + 1}',
                              style: const TextStyle(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppTheme.lightTextColor,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: weeklyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final kwh = entry.value['kwh'] as double;
                    final hasData = kwh > 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: kwh > 0 ? kwh : 0.1,
                          gradient: hasData
                              ? LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade300,
                                  ],
                                ),
                          width: 28,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousBudgetCard(BudgetModel budget) {
    final monthName = DateFormat(
      'MMMM',
    ).format(DateTime(budget.year, budget.month));
    final percentUsed = budget.usagePercentage;

    Color statusColor;
    if (percentUsed >= 1.0) {
      statusColor = AppTheme.errorColor;
    } else if (percentUsed >= 0.8) {
      statusColor = AppTheme.warningColor;
    } else {
      statusColor = AppTheme.successColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      '$monthName ${budget.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.budgetPlanName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.8),
                        statusColor.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    percentUsed >= 1.0 ? 'Over Budget' : 'Under Budget',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        '${budget.kwh.toStringAsFixed(1)} kWh',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Used',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        '${budget.totalUsedKwh.toStringAsFixed(1)} kWh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        percentUsed >= 1.0 ? 'Over' : 'Remaining',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      Text(
                        '${budget.remainingKwh.abs().toStringAsFixed(1)} kWh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: percentUsed >= 1.0
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to create new budget
  Future<void> _showCreateBudgetDialog() async {
    // Navigate to budget plan selection screen
    final result = await Navigator.pushNamed(
      context,
      '/new-budget-plan-selection',
    );

    if (result != null && mounted) {
      // Budget was created successfully
      await _loadBudgets();
    }
  }

  // Dialog to edit weekly kWh
  Future<void> _showEditWeekDialog(int weekNumber, double currentKwh) async {
    final controller = TextEditingController(
      text: currentKwh > 0 ? currentKwh.toStringAsFixed(1) : '',
    );
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Week $weekNumber Usage'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'kWh Usage',
                  border: OutlineInputBorder(),
                  suffixText: 'kWh',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter kWh usage';
                  }
                  final kwh = double.tryParse(value);
                  if (kwh == null || kwh < 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final kwh = double.parse(controller.text);
                Navigator.pop(context);

                final success = await Provider.of<NewBudgetService>(
                  context,
                  listen: false,
                ).updateWeeklyKwh(weekNumber: weekNumber, kwh: kwh);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Week $weekNumber updated successfully'
                            : 'Failed to update week $weekNumber',
                      ),
                      backgroundColor: success
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Confirm delete budget
  Future<void> _confirmDeleteBudget(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await Provider.of<NewBudgetService>(
        context,
        listen: false,
      ).deleteCurrentBudget();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Budget deleted successfully'
                  : 'Failed to delete budget',
            ),
            backgroundColor: success
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
