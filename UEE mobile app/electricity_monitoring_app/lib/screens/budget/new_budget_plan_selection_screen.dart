import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/new_budget_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/background_container.dart';

class NewBudgetPlanSelectionScreen extends StatefulWidget {
  static const routeName = '/new-budget-plan-selection';

  const NewBudgetPlanSelectionScreen({super.key});

  @override
  State<NewBudgetPlanSelectionScreen> createState() =>
      _NewBudgetPlanSelectionScreenState();
}

class _NewBudgetPlanSelectionScreenState
    extends State<NewBudgetPlanSelectionScreen> {
  bool _isLoading = false;
  String? _selectedPlanId;

  // Predefined budget plans
  final List<Map<String, dynamic>> _budgetPlans = [
    {
      'id': 'economy',
      'name': 'Economy Plan',
      'description':
          'Perfect for small households with minimal electricity usage',
      'kwh': 120.0,
      'price': 4500.0,
      'icon': Icons.eco,
      'color': Colors.green,
      'recommendations': [
        'Use energy-efficient LED bulbs',
        'Turn off appliances when not in use',
        'Optimize air conditioner usage',
      ],
    },
    {
      'id': 'standard',
      'name': 'Standard Plan',
      'description':
          'Ideal for average households with moderate electricity needs',
      'kwh': 200.0,
      'price': 7500.0,
      'icon': Icons.home,
      'color': Colors.blue,
      'recommendations': [
        'Use appliances during off-peak hours',
        'Regular maintenance of electrical equipment',
        'Consider solar panels for long-term savings',
      ],
    },
    {
      'id': 'premium',
      'name': 'Premium Plan',
      'description': 'Suitable for large households or high-consumption needs',
      'kwh': 300.0,
      'price': 11000.0,
      'icon': Icons.star,
      'color': Colors.purple,
      'recommendations': [
        'Invest in energy-efficient appliances',
        'Use smart home automation for energy management',
        'Monitor usage regularly to optimize consumption',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Select Budget Plan',
        showBackButton: true,
      ),
      body: BackgroundContainer(
        child: _isLoading
            ? const LoadingIndicator(message: 'Creating budget...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    ..._budgetPlans.map((plan) => _buildPlanCard(plan)),
                    const SizedBox(height: 24),
                    _buildCustomPlanOption(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Budget Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select a plan that matches your needs',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightTextColor,
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

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final bool isSelected = _selectedPlanId == plan['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Card(
          elevation: isSelected ? 4 : 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (plan['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        plan['icon'] as IconData,
                        color: plan['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['name'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan['description'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.lightTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly kWh',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(plan['kwh'] as double).toStringAsFixed(0)} kWh',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Cost',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.lightTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LKR ${(plan['price'] as double).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...(plan['recommendations'] as List<String>).map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: plan['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAndCreateBudget(plan),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Select This Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPlanOption() {
    return GestureDetector(
      onTap: _showCreateCustomPlanDialog,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppTheme.secondaryColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: AppTheme.secondaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Custom Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Set your own kWh and cost limits',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.lightTextColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndCreateBudget(Map<String, dynamic> plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Budget Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to create a budget with the ${plan['name']}:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildConfirmRow('Monthly Limit', '${plan['kwh']} kWh'),
            const SizedBox(height: 8),
            _buildConfirmRow('Estimated Cost', 'LKR ${plan['price']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This budget will be valid for the current month only.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Budget'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _createBudget(
        planName: plan['name'] as String,
        kwh: plan['kwh'] as double,
        price: plan['price'] as double,
      );
    }
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.lightTextColor),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _createBudget({
    required String planName,
    required double kwh,
    required double price,
  }) async {
    setState(() => _isLoading = true);

    try {
      final budgetService = Provider.of<NewBudgetService>(
        context,
        listen: false,
      );
      final success = await budgetService.createMonthlyBudget(
        budgetPlanName: planName,
        kwh: kwh,
        price: price,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$planName created successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create budget. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCreateCustomPlanDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: 'Custom Plan');
    final kwhController = TextEditingController(text: '150');
    final priceController = TextEditingController(text: '6000');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Plan'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a plan name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kwhController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly kWh Limit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bolt),
                    suffixText: 'kWh',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter kWh limit';
                    }
                    final kwh = double.tryParse(value);
                    if (kwh == null || kwh <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Monthly Cost',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: 'LKR',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter estimated cost';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _createBudget(
        planName: nameController.text,
        kwh: double.parse(kwhController.text),
        price: double.parse(priceController.text),
      );
    }
  }
}
