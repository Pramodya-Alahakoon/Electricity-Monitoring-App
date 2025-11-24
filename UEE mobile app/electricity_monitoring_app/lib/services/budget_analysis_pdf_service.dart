import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/new_budget_model.dart';
import 'budget_analysis_service.dart';

class BudgetAnalysisPdfService {
  /// Generate comprehensive budget analysis report with charts
  Future<void> generateAnalysisReport(
    BudgetModel selectedBudget,
    MonthComparison? comparison,
    Map<String, dynamic> statistics,
  ) async {
    final pdf = pw.Document();
    final monthName = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(selectedBudget.year, selectedBudget.month));

    // Add pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            // Title Page
            _buildTitlePage(monthName, selectedBudget),
            pw.SizedBox(height: 30),

            // Overview Section
            _buildOverviewSection(selectedBudget),
            pw.SizedBox(height: 25),

            // Weekly Distribution Bar Chart
            _buildWeeklyDistributionChart(selectedBudget),
            pw.SizedBox(height: 25),

            // Usage Pie Chart
            _buildUsagePieChart(selectedBudget),

            // Page break for next sections
            pw.NewPage(),

            // Usage Statistics
            _buildUsageStatistics(statistics),
            pw.SizedBox(height: 25),

            // Month Comparison
            if (comparison != null && comparison.previousMonth != null) ...[
              _buildComparisonSection(comparison),
              pw.SizedBox(height: 25),

              // Week-by-Week Comparison Chart
              _buildWeekByWeekComparison(comparison),
              pw.SizedBox(height: 25),
            ],

            // Insights Section
            if (comparison != null && comparison.insights.isNotEmpty) ...[
              _buildInsightsSection(comparison.insights),
              pw.SizedBox(height: 25),
            ],

            // Predictions Section
            if (comparison != null && comparison.predictions.isNotEmpty) ...[
              _buildPredictionsSection(comparison.predictions),
              pw.SizedBox(height: 25),
            ],

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    // Save and open the PDF
    final output = await _getReportFilePath(
      'budget_analysis_${selectedBudget.year}_${selectedBudget.month.toString().padLeft(2, '0')}.pdf',
    );
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    OpenFile.open(output);
  }

  /// Build title page
  pw.Widget _buildTitlePage(String monthName, BudgetModel budget) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Budget Analysis Report',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            monthName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Budget Plan:',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    budget.budgetPlanName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Generated:',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build overview section
  pw.Widget _buildOverviewSection(BudgetModel budget) {
    final percentUsed = budget.usagePercentage * 100;
    PdfColor statusColor;
    String status;

    if (percentUsed >= 100) {
      statusColor = PdfColors.red700;
      status = 'Over Budget';
    } else if (percentUsed >= 80) {
      statusColor = PdfColors.orange700;
      status = 'Warning';
    } else if (percentUsed >= 50) {
      statusColor = PdfColors.blue700;
      status = 'On Track';
    } else {
      statusColor = PdfColors.green700;
      status = 'Excellent';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Budget Overview',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  status,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox(
                'Budget',
                '${budget.kwh.toStringAsFixed(0)} kWh',
                PdfColors.blue700,
              ),
              _buildStatBox(
                'Used',
                '${budget.totalUsedKwh.toStringAsFixed(1)} kWh',
                statusColor,
              ),
              _buildStatBox(
                'Remaining',
                '${budget.remainingKwh.toStringAsFixed(1)} kWh',
                budget.remainingKwh >= 0
                    ? PdfColors.green700
                    : PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          // Progress bar
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Stack(
                  children: [
                    pw.Container(
                      width: (percentUsed / 100) * 500, // Approximate width
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '${percentUsed.toStringAsFixed(1)}% of budget used',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stat box
  pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Build weekly distribution bar chart
  pw.Widget _buildWeeklyDistributionChart(BudgetModel budget) {
    final weeks = [budget.week1, budget.week2, budget.week3, budget.week4];
    final maxValue = weeks.reduce((a, b) => a > b ? a : b);
    final chartHeight = 180.0;
    final chartWidth = 450.0;
    final barWidth = 70.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Weekly Breakdown',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 20),
          // Chart
          pw.Container(
            height: chartHeight,
            width: chartWidth,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                final barHeight = maxValue > 0
                    ? (weeks[index] / maxValue) * (chartHeight - 40)
                    : 0.0;
                final colors = [
                  PdfColors.blue400,
                  PdfColors.green400,
                  PdfColors.orange400,
                  PdfColors.purple400,
                ];

                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      weeks[index].toStringAsFixed(1),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: barWidth,
                      height: barHeight.toDouble(),
                      decoration: pw.BoxDecoration(
                        color: colors[index],
                        borderRadius: const pw.BorderRadius.vertical(
                          top: pw.Radius.circular(6),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Week ${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Build usage pie chart (as horizontal bars)
  pw.Widget _buildUsagePieChart(BudgetModel budget) {
    final weeks = [budget.week1, budget.week2, budget.week3, budget.week4];
    final total = weeks.reduce((a, b) => a + b);

    if (total <= 0) {
      return pw.SizedBox();
    }

    final colors = [
      PdfColors.blue400,
      PdfColors.green400,
      PdfColors.orange400,
      PdfColors.purple400,
    ];

    final percentages = weeks.map((w) => (w / total * 100)).toList();
    final maxBarWidth = 350.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Usage Distribution',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 20),
          // Horizontal bar chart
          ...List.generate(4, (index) {
            final percentage = percentages[index];
            final barWidth = (percentage / 100) * maxBarWidth;

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Week label
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text(
                      'Week ${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Horizontal bar
                  pw.Expanded(
                    child: pw.Stack(
                      children: [
                        // Background bar
                        pw.Container(
                          height: 28,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                        ),
                        // Filled bar
                        pw.Container(
                          height: 28,
                          width: barWidth,
                          decoration: pw.BoxDecoration(
                            color: colors[index],
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // kWh value
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      '${weeks[index].toStringAsFixed(1)} kWh',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: colors[index],
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          // Total summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Usage',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                '${total.toStringAsFixed(1)} kWh',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build usage statistics section
  pw.Widget _buildUsageStatistics(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Usage Statistics',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),
          _buildStatRow(
            'Average Weekly',
            '${stats['average'].toStringAsFixed(1)} kWh',
            PdfColors.blue700,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          _buildStatRow(
            'Highest Week',
            '${stats['highest'].toStringAsFixed(1)} kWh',
            PdfColors.red700,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          _buildStatRow(
            'Lowest Week',
            '${stats['lowest'].toStringAsFixed(1)} kWh',
            PdfColors.green700,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          _buildStatRow(
            'Consistency Score',
            '${stats['consistency'].toStringAsFixed(0)}%',
            _getConsistencyColor(stats['consistency']),
          ),
        ],
      ),
    );
  }

  /// Build stat row
  pw.Widget _buildStatRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Get consistency color
  PdfColor _getConsistencyColor(double consistency) {
    if (consistency >= 80) return PdfColors.green700;
    if (consistency >= 60) return PdfColors.blue700;
    if (consistency >= 40) return PdfColors.orange700;
    return PdfColors.red700;
  }

  /// Build comparison section
  pw.Widget _buildComparisonSection(MonthComparison comparison) {
    final current = comparison.currentMonth;
    final previous = comparison.previousMonth!;
    final currentMonthName = DateFormat(
      'MMMM',
    ).format(DateTime(current.year, current.month));
    final prevMonthName = DateFormat(
      'MMMM',
    ).format(DateTime(previous.year, previous.month));

    PdfColor trendColor;
    String trendIcon;
    String trendLabel;

    switch (comparison.trend) {
      case 'improving':
        trendColor = PdfColors.green700;
        trendIcon = '↓';
        trendLabel = 'Improving';
        break;
      case 'declining':
        trendColor = PdfColors.red700;
        trendIcon = '↑';
        trendLabel = 'Increasing Usage';
        break;
      default:
        trendColor = PdfColors.blue700;
        trendIcon = '→';
        trendLabel = 'Stable';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Month Comparison',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: trendColor.shade(0.2),
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      trendIcon,
                      style: pw.TextStyle(fontSize: 16, color: trendColor),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      trendLabel,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: trendColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${comparison.usageChange >= 0 ? '+' : ''}${comparison.usageChange.toStringAsFixed(1)}% change',
            style: pw.TextStyle(fontSize: 11, color: trendColor),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMonthComparisonBox(
                  prevMonthName,
                  previous,
                  PdfColors.grey600,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMonthComparisonBox(
                  currentMonthName,
                  current,
                  PdfColors.blue700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build month comparison box
  pw.Widget _buildMonthComparisonBox(
    String monthName,
    BudgetModel budget,
    PdfColor color,
  ) {
    final weeks = [budget.week1, budget.week2, budget.week3, budget.week4];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color.shade(0.3)),
        borderRadius: pw.BorderRadius.circular(8),
        color: color.shade(0.05),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            monthName,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total: ${budget.totalUsedKwh.toStringAsFixed(1)} kWh',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...List.generate(4, (index) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Week ${index + 1}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    weeks[index].toStringAsFixed(1),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build week-by-week comparison chart
  pw.Widget _buildWeekByWeekComparison(MonthComparison comparison) {
    final current = comparison.currentMonth;
    final previous = comparison.previousMonth!;
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
    final maxValue = [
      ...currentWeeks,
      ...previousWeeks,
    ].reduce((a, b) => a > b ? a : b);
    final chartHeight = 160.0;
    final barWidth = 25.0;

    final currentMonthName = DateFormat(
      'MMM',
    ).format(DateTime(current.year, current.month));
    final prevMonthName = DateFormat(
      'MMM',
    ).format(DateTime(previous.year, previous.month));

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Week-by-Week Comparison',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 20),
          // Chart
          pw.Container(
            height: chartHeight,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                final prevHeight = maxValue > 0
                    ? (previousWeeks[index] / maxValue) * (chartHeight - 40)
                    : 0.0;
                final currHeight = maxValue > 0
                    ? (currentWeeks[index] / maxValue) * (chartHeight - 40)
                    : 0.0;

                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Previous month bar
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: barWidth,
                              height: prevHeight.toDouble(),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey400,
                                borderRadius: const pw.BorderRadius.vertical(
                                  top: pw.Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 4),
                        // Current month bar
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: barWidth,
                              height: currHeight.toDouble(),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue600,
                                borderRadius: const pw.BorderRadius.vertical(
                                  top: pw.Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Week ${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          pw.SizedBox(height: 16),
          // Legend
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(width: 14, height: 14, color: PdfColors.grey400),
              pw.SizedBox(width: 6),
              pw.Text(prevMonthName, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(width: 20),
              pw.Container(width: 14, height: 14, color: PdfColors.blue600),
              pw.SizedBox(width: 6),
              pw.Text(
                currentMonthName,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build insights section
  pw.Widget _buildInsightsSection(List<String> insights) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
        color: PdfColors.orange50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('💡', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Text(
                'Insights',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          ...insights.map((insight) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.orange700,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text(
                      insight,
                      style: const pw.TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build predictions section
  pw.Widget _buildPredictionsSection(List<String> predictions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('📈', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Text(
                'Predictions & Recommendations',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          ...predictions.map((prediction) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '→',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.blue700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text(
                      prediction,
                      style: const pw.TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build footer
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Electricity Monitoring App - Budget Analysis Report',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This report provides comprehensive analysis of your electricity consumption and budget performance.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get report file path
  Future<String> _getReportFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
