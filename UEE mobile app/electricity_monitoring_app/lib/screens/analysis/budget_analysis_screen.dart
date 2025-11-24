import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/new_budget_model.dart';
import '../../services/new_budget_service.dart';
import '../../services/budget_analysis_service.dart';
import '../../services/budget_analysis_pdf_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class BudgetAnalysisScreen extends StatefulWidget {
  static const routeName = '/budget-analysis';
  final bool showBackButton;

  const BudgetAnalysisScreen({super.key, this.showBackButton = true});

  @override
  State<BudgetAnalysisScreen> createState() => _BudgetAnalysisScreenState();
}

class _BudgetAnalysisScreenState extends State<BudgetAnalysisScreen> {
  BudgetModel? _selectedBudget;
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  final BudgetAnalysisService _analysisService = BudgetAnalysisService();
  final BudgetAnalysisPdfService _pdfService = BudgetAnalysisPdfService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final budgetService = Provider.of<NewBudgetService>(context, listen: false);
    await budgetService.fetchBudgets();

    // Select current budget by default
    if (budgetService.currentBudget != null) {
      setState(() {
        _selectedBudget = budgetService.currentBudget;
      });
      _loadComparison();
    } else if (budgetService.previousBudgets.isNotEmpty) {
      setState(() {
        _selectedBudget = budgetService.previousBudgets.first;
      });
      _loadComparison();
    }
  }

  Future<void> _loadComparison() async {
    if (_selectedBudget == null) return;

    setState(() => _isLoading = true);
    await _analysisService.compareMonths(_selectedBudget!);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Budget Analysis',
        showBackButton: widget.showBackButton,
      ),
      body: _selectedBudget == null
          ? _buildNoBudgetView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const LoadingIndicator(message: 'Analyzing data...')
                  else ...[
                    _buildOverviewCard(),
                    const SizedBox(height: 16),
                    _buildWeeklyDistributionRow(),
                    const SizedBox(height: 16),
                    _buildUsageStatisticsCard(),
                    const SizedBox(height: 16),
                    _buildComparisonSection(),
                    const SizedBox(height: 16),
                    _buildInsightsCard(),
                    const SizedBox(height: 16),
                    _buildPredictionsCard(),
                    const SizedBox(height: 24),
                    _buildGeneratePdfButton(),
                    const SizedBox(height: 20),
                  ],
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
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Budget Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a budget to start analyzing',
            style: TextStyle(color: AppTheme.lightTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Consumer<NewBudgetService>(
      builder: (context, budgetService, child) {
        final allBudgets = [
          if (budgetService.currentBudget != null) budgetService.currentBudget!,
          ...budgetService.previousBudgets,
        ];

        if (allBudgets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                  value: _selectedBudget?.id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: allBudgets.map((budget) {
                    final monthName = DateFormat(
                      'MMMM yyyy',
                    ).format(DateTime(budget.year, budget.month));
                    final isCurrent =
                        budget.id == budgetService.currentBudget?.id;
                    return DropdownMenuItem(
                      value: budget.id,
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
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
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
                      final selected = allBudgets.firstWhere(
                        (b) => b.id == value,
                      );
                      setState(() {
                        _selectedBudget = selected;
                      });
                      _loadComparison();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard() {
    if (_selectedBudget == null) return const SizedBox.shrink();

    final budget = _selectedBudget!;
    final percentUsed = budget.usagePercentage * 100;
    final monthName = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(budget.year, budget.month));

    Color statusColor;
    String status;
    if (percentUsed >= 100) {
      statusColor = AppTheme.errorColor;
      status = 'Over Budget';
    } else if (percentUsed >= 80) {
      statusColor = AppTheme.warningColor;
      status = 'Warning';
    } else if (percentUsed >= 50) {
      statusColor = AppTheme.primaryColor;
      status = 'On Track';
    } else {
      statusColor = AppTheme.successColor;
      status = 'Excellent';
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
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
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.budgetPlanName,
                      style: const TextStyle(
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Budget',
                  '${budget.kwh.toStringAsFixed(0)} kWh',
                  AppTheme.primaryColor,
                ),
                _buildStatColumn(
                  'Used',
                  '${budget.totalUsedKwh.toStringAsFixed(1)} kWh',
                  statusColor,
                ),
                _buildStatColumn(
                  'Remaining',
                  '${budget.remainingKwh.toStringAsFixed(1)} kWh',
                  budget.remainingKwh >= 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${percentUsed.toStringAsFixed(1)}% of budget used',
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyDistributionRow() {
    if (_selectedBudget == null) return const SizedBox.shrink();

    final budget = _selectedBudget!;
    final weeks = [budget.week1, budget.week2, budget.week3, budget.week4];

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar Chart Section
            const Text(
              'Weekly Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weeks.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} kWh',
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Week ${value.toInt() + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300], strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(4, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: weeks[index],
                          color: _getWeekColor(index),
                          width: 50,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            // Pie Chart Section
            const Text(
              'Usage Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: weeks.reduce((a, b) => a + b) > 0
                        ? PieChart(
                            PieChartData(
                              sections: List.generate(4, (index) {
                                final total = weeks.reduce((a, b) => a + b);
                                final percentage = total > 0
                                    ? (weeks[index] / total * 100)
                                    : 0;
                                return PieChartSectionData(
                                  value: weeks[index],
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  color: _getWeekColor(index),
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                              sectionsSpace: 2,
                              centerSpaceRadius: 0,
                            ),
                          )
                        : Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final total = weeks.reduce((a, b) => a + b);
                      final percentage = total > 0
                          ? (weeks[index] / total * 100)
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _getWeekColor(index),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Week ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${weeks[index].toStringAsFixed(1)} kWh',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getWeekColor(int weekIndex) {
    const colors = [
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFFFFA726),
      Color(0xFFAB47BC),
    ];
    return colors[weekIndex % colors.length];
  }

  Widget _buildUsageStatisticsCard() {
    if (_selectedBudget == null) return const SizedBox.shrink();

    final stats = _analysisService.getUsageStatistics(_selectedBudget!);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatRow(
              'Average Weekly',
              '${stats['average'].toStringAsFixed(1)} kWh',
              Icons.show_chart,
              AppTheme.primaryColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Highest Week',
              '${stats['highest'].toStringAsFixed(1)} kWh',
              Icons.trending_up,
              AppTheme.errorColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Lowest Week',
              '${stats['lowest'].toStringAsFixed(1)} kWh',
              Icons.trending_down,
              AppTheme.successColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Consistency Score',
              '${stats['consistency'].toStringAsFixed(0)}%',
              Icons.check_circle,
              _getConsistencyColor(stats['consistency']),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConsistencyColor(double consistency) {
    if (consistency >= 80) return AppTheme.successColor;
    if (consistency >= 60) return AppTheme.primaryColor;
    if (consistency >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.lightTextColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonSection() {
    final comparison = _analysisService.comparison;
    if (comparison == null || comparison.previousMonth == null) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.compare_arrows,
                size: 48,
                color: AppTheme.lightTextColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Previous Month Data',
                style: TextStyle(fontSize: 16, color: AppTheme.lightTextColor),
              ),
            ],
          ),
        ),
      );
    }

    final current = comparison.currentMonth;
    final previous = comparison.previousMonth!;
    final currentMonthName = DateFormat(
      'MMMM',
    ).format(DateTime(current.year, current.month));
    final prevMonthName = DateFormat(
      'MMMM',
    ).format(DateTime(previous.year, previous.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with trend indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getTrendIcon(comparison.trend),
                color: _getTrendColor(comparison.trend),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Month Comparison',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_getTrendLabel(comparison.trend)} - ${comparison.usageChange >= 0 ? '+' : ''}${comparison.usageChange.toStringAsFixed(1)}% change',
                      style: TextStyle(
                        fontSize: 13,
                        color: _getTrendColor(comparison.trend),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Side-by-side month cards
        Row(
          children: [
            // Previous Month
            Expanded(
              child: _buildMonthComparisonCard(
                prevMonthName,
                previous,
                isPrevious: true,
              ),
            ),
            const SizedBox(width: 16),
            // Current Month
            Expanded(
              child: _buildMonthComparisonCard(
                currentMonthName,
                current,
                isPrevious: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Detailed week-by-week comparison chart
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Week-by-Week Comparison',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxWeekValue(current, previous) * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final month = rodIndex == 0
                                ? prevMonthName
                                : currentMonthName;
                            return BarTooltipItem(
                              '$month\n${rod.toY.toStringAsFixed(1)} kWh',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Week ${value.toInt() + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildComparisonBarGroups(current, previous),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(prevMonthName, Colors.grey[400]!),
                    const SizedBox(width: 24),
                    _buildLegendItem(currentMonthName, AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthComparisonCard(
    String monthName,
    BudgetModel budget, {
    required bool isPrevious,
  }) {
    final weeks = [budget.week1, budget.week2, budget.week3, budget.week4];
    final color = isPrevious ? Colors.grey[400]! : AppTheme.primaryColor;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrevious
              ? Colors.grey[300]!
              : AppTheme.primaryColor.withOpacity(0.3),
          width: isPrevious ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMonthStat(
              'Total',
              '${budget.totalUsedKwh.toStringAsFixed(1)} kWh',
              color,
            ),
            const Divider(height: 20),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week ${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                    Text(
                      '${weeks[index].toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _getMaxWeekValue(BudgetModel current, BudgetModel previous) {
    final allWeeks = [
      current.week1,
      current.week2,
      current.week3,
      current.week4,
      previous.week1,
      previous.week2,
      previous.week3,
      previous.week4,
    ];
    return allWeeks.reduce((a, b) => a > b ? a : b);
  }

  List<BarChartGroupData> _buildComparisonBarGroups(
    BudgetModel current,
    BudgetModel previous,
  ) {
    final currentWeeks = [
      current.week1,
      current.week2,
      current.week3,
      current.week4,
    ];
    final previousWeeks = [
      previous.week1,
      previous.week2,
      previous.week3,
      previous.week4,
    ];

    return List.generate(4, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: previousWeeks[index],
            color: Colors.grey[400],
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: currentWeeks[index],
            color: AppTheme.primaryColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return AppTheme.successColor;
      case 'declining':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_down;
      case 'declining':
        return Icons.trending_up;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'improving':
        return 'Improving';
      case 'declining':
        return 'Increasing Usage';
      default:
        return 'Stable';
    }
  }

  Widget _buildInsightsCard() {
    final comparison = _analysisService.comparison;
    if (comparison == null || comparison.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...comparison.insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsCard() {
    final comparison = _analysisService.comparison;
    if (comparison == null || comparison.predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph, color: AppTheme.secondaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Predictions & Recommendations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...comparison.predictions.map((prediction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prediction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratePdfButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isGeneratingPdf ? null : _generatePdfReport,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGeneratingPdf)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isGeneratingPdf
                      ? 'Generating PDF...'
                      : 'Generate PDF Report',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    if (_selectedBudget == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      // Get statistics
      final statistics = _analysisService.getUsageStatistics(_selectedBudget!);

      // Get comparison data
      final comparison = _analysisService.comparison;

      // Generate PDF
      await _pdfService.generateAnalysisReport(
        _selectedBudget!,
        comparison,
        statistics,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PDF report generated successfully!',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error generating PDF: ${e.toString()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}
