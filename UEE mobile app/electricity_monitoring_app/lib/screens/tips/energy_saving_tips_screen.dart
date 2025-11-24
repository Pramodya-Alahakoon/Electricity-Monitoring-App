import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class EnergySavingTipsScreen extends StatefulWidget {
  static const routeName = '/energy-saving-tips';

  const EnergySavingTipsScreen({super.key});

  @override
  State<EnergySavingTipsScreen> createState() => _EnergySavingTipsScreenState();
}

class _EnergySavingTipsScreenState extends State<EnergySavingTipsScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  // Predefined energy saving tips
  final List<Map<String, dynamic>> _allTips = [
    // Lighting Tips
    {
      'title': 'Switch to LED Bulbs',
      'description':
          'Replace incandescent bulbs with LED bulbs. LEDs use up to 75% less energy and last 25 times longer, significantly reducing electricity costs.',
      'category': 'Lighting',
      'icon': Icons.lightbulb,
      'estimatedSavings': 15000.0,
      'difficulty': 'Easy',
      'color': Colors.amber,
    },
    {
      'title': 'Use Natural Light',
      'description':
          'Open curtains and blinds during daytime to maximize natural light. This reduces the need for artificial lighting and can save significant energy.',
      'category': 'Lighting',
      'icon': Icons.wb_sunny,
      'estimatedSavings': 8000.0,
      'difficulty': 'Easy',
      'color': Colors.amber,
    },
    {
      'title': 'Install Motion Sensors',
      'description':
          'Use motion sensor lights in areas like hallways, bathrooms, and garages. They automatically turn off when no one is present.',
      'category': 'Lighting',
      'icon': Icons.sensors,
      'estimatedSavings': 12000.0,
      'difficulty': 'Medium',
      'color': Colors.amber,
    },

    // Cooling & Heating Tips
    {
      'title': 'Optimize AC Temperature',
      'description':
          'Set your air conditioner to 24-26°C. Every degree lower can increase energy consumption by 6-8%. Use ceiling fans to circulate cool air.',
      'category': 'Cooling & Heating',
      'icon': Icons.ac_unit,
      'estimatedSavings': 25000.0,
      'difficulty': 'Easy',
      'color': Colors.blue,
    },
    {
      'title': 'Regular AC Maintenance',
      'description':
          'Clean or replace AC filters monthly. A clogged filter makes the unit work harder, consuming 5-15% more electricity.',
      'category': 'Cooling & Heating',
      'icon': Icons.cleaning_services,
      'estimatedSavings': 10000.0,
      'difficulty': 'Easy',
      'color': Colors.blue,
    },
    {
      'title': 'Use Ceiling Fans',
      'description':
          'Ceiling fans use 90% less energy than air conditioners. Use them to circulate air and reduce AC dependency.',
      'category': 'Cooling & Heating',
      'icon': Icons.wind_power,
      'estimatedSavings': 18000.0,
      'difficulty': 'Easy',
      'color': Colors.blue,
    },
    {
      'title': 'Seal Air Leaks',
      'description':
          'Seal gaps around doors and windows to prevent cool air from escaping. This can reduce AC usage by up to 20%.',
      'category': 'Cooling & Heating',
      'icon': Icons.door_front_door,
      'estimatedSavings': 15000.0,
      'difficulty': 'Medium',
      'color': Colors.blue,
    },

    // Kitchen Appliances
    {
      'title': 'Use Pressure Cookers',
      'description':
          'Pressure cookers use 50-75% less energy than traditional cooking methods. They cook food faster and save electricity.',
      'category': 'Kitchen',
      'icon': Icons.kitchen,
      'estimatedSavings': 12000.0,
      'difficulty': 'Easy',
      'color': Colors.orange,
    },
    {
      'title': 'Defrost Refrigerator Regularly',
      'description':
          'Keep your freezer frost-free. Frost buildup makes the refrigerator work harder, increasing energy consumption by up to 30%.',
      'category': 'Kitchen',
      'icon': Icons.kitchen,
      'estimatedSavings': 8000.0,
      'difficulty': 'Easy',
      'color': Colors.orange,
    },
    {
      'title': 'Match Pot Size to Burner',
      'description':
          'Use appropriately sized pots on stove burners. A small pot on a large burner wastes 40% of the heat energy.',
      'category': 'Kitchen',
      'icon': Icons.local_dining,
      'estimatedSavings': 5000.0,
      'difficulty': 'Easy',
      'color': Colors.orange,
    },
    {
      'title': 'Cover Pots While Cooking',
      'description':
          'Always use lids when cooking. This traps heat, reduces cooking time by 25%, and saves significant energy.',
      'category': 'Kitchen',
      'icon': Icons.soup_kitchen,
      'estimatedSavings': 6000.0,
      'difficulty': 'Easy',
      'color': Colors.orange,
    },

    // Water Heating
    {
      'title': 'Use Solar Water Heater',
      'description':
          'Install a solar water heater. It can reduce water heating costs by 50-80% and pays for itself in 3-5 years.',
      'category': 'Water Heating',
      'icon': Icons.water_drop,
      'estimatedSavings': 40000.0,
      'difficulty': 'Hard',
      'color': Colors.teal,
    },
    {
      'title': 'Lower Water Heater Temperature',
      'description':
          'Set your water heater to 50-55°C. Higher temperatures waste energy and can cause scalding.',
      'category': 'Water Heating',
      'icon': Icons.thermostat,
      'estimatedSavings': 10000.0,
      'difficulty': 'Easy',
      'color': Colors.teal,
    },
    {
      'title': 'Take Shorter Showers',
      'description':
          'Reduce shower time by 2-3 minutes. This saves both water and the energy needed to heat it.',
      'category': 'Water Heating',
      'icon': Icons.shower,
      'estimatedSavings': 8000.0,
      'difficulty': 'Easy',
      'color': Colors.teal,
    },

    // Laundry
    {
      'title': 'Wash Clothes in Cold Water',
      'description':
          'Use cold water for washing clothes. About 90% of washing machine energy goes to heating water. Cold water works just as well for most loads.',
      'category': 'Laundry',
      'icon': Icons.local_laundry_service,
      'estimatedSavings': 15000.0,
      'difficulty': 'Easy',
      'color': Colors.purple,
    },
    {
      'title': 'Air Dry Clothes',
      'description':
          'Use a clothesline or drying rack instead of a dryer. Dryers are among the most energy-intensive appliances.',
      'category': 'Laundry',
      'icon': Icons.dry_cleaning,
      'estimatedSavings': 20000.0,
      'difficulty': 'Easy',
      'color': Colors.purple,
    },
    {
      'title': 'Run Full Loads Only',
      'description':
          'Always run full loads in your washing machine and dishwasher. This maximizes efficiency and reduces energy per item.',
      'category': 'Laundry',
      'icon': Icons.local_laundry_service,
      'estimatedSavings': 10000.0,
      'difficulty': 'Easy',
      'color': Colors.purple,
    },

    // Electronics
    {
      'title': 'Unplug Devices When Not in Use',
      'description':
          'Many devices consume power even when turned off (phantom load). Unplug chargers, TVs, and other electronics to save energy.',
      'category': 'Electronics',
      'icon': Icons.power_settings_new,
      'estimatedSavings': 12000.0,
      'difficulty': 'Easy',
      'color': Colors.red,
    },
    {
      'title': 'Use Smart Power Strips',
      'description':
          'Smart power strips cut power to devices in standby mode. This can reduce phantom power consumption by up to 75%.',
      'category': 'Electronics',
      'icon': Icons.electrical_services,
      'estimatedSavings': 15000.0,
      'difficulty': 'Medium',
      'color': Colors.red,
    },
    {
      'title': 'Enable Power Saving Mode',
      'description':
          'Use power-saving settings on computers, TVs, and other electronics. Enable sleep mode after 10-15 minutes of inactivity.',
      'category': 'Electronics',
      'icon': Icons.settings_power,
      'estimatedSavings': 8000.0,
      'difficulty': 'Easy',
      'color': Colors.red,
    },
    {
      'title': 'Choose Energy-Efficient Devices',
      'description':
          'When buying new appliances, choose those with high energy efficiency ratings. They cost more upfront but save money long-term.',
      'category': 'Electronics',
      'icon': Icons.star,
      'estimatedSavings': 30000.0,
      'difficulty': 'Medium',
      'color': Colors.red,
    },

    // General Tips
    {
      'title': 'Use Timer Switches',
      'description':
          'Install timer switches for outdoor lights, water heaters, and other appliances. Automate turning them off when not needed.',
      'category': 'General',
      'icon': Icons.schedule,
      'estimatedSavings': 10000.0,
      'difficulty': 'Medium',
      'color': Colors.green,
    },
    {
      'title': 'Regular Energy Audits',
      'description':
          'Monitor your electricity usage regularly. Understanding consumption patterns helps identify areas for improvement.',
      'category': 'General',
      'icon': Icons.analytics,
      'estimatedSavings': 20000.0,
      'difficulty': 'Easy',
      'color': Colors.green,
    },
    {
      'title': 'Insulate Your Home',
      'description':
          'Proper insulation reduces heating and cooling needs by up to 30%. Focus on attics, walls, and floors.',
      'category': 'General',
      'icon': Icons.home,
      'estimatedSavings': 35000.0,
      'difficulty': 'Hard',
      'color': Colors.green,
    },
    {
      'title': 'Plant Trees for Shade',
      'description':
          'Plant trees around your home to provide natural shade. This can reduce indoor temperatures and AC usage.',
      'category': 'General',
      'icon': Icons.park,
      'estimatedSavings': 15000.0,
      'difficulty': 'Medium',
      'color': Colors.green,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final categories = _allTips
        .map((tip) => tip['category'] as String)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<Map<String, dynamic>> get _filteredTips {
    var tips = _allTips;

    // Filter by category
    if (_selectedCategory != null) {
      tips = tips.where((tip) => tip['category'] == _selectedCategory).toList();
    }

    // Filter by search text
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      tips = tips.where((tip) {
        final title = (tip['title'] as String).toLowerCase();
        final description = (tip['description'] as String).toLowerCase();
        final category = (tip['category'] as String).toLowerCase();
        return title.contains(searchText) ||
            description.contains(searchText) ||
            category.contains(searchText);
      }).toList();
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Energy Saving Tips'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tips...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Category filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      ..._categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tips count
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredTips.length} ${_filteredTips.length == 1 ? 'Tip' : 'Tips'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const Spacer(),
                if (_selectedCategory != null ||
                    _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),

          // Tips List
          Expanded(
            child: _filteredTips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tips found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTips.length,
                    itemBuilder: (context, index) {
                      return _buildTipCard(_filteredTips[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTipDetails(tip),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (tip['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tip['icon'] as IconData,
                      color: tip['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tip['category'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildDifficultyBadge(tip['difficulty'] as String),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tip['description'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Est. savings: LKR ${(tip['estimatedSavings'] as double).toStringAsFixed(0)}/year',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty) {
      case 'Easy':
        color = Colors.green;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showTipDetails(Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (tip['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        tip['icon'] as IconData,
                        color: tip['color'] as Color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip['title'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tip['category'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildDifficultyBadge(
                                tip['difficulty'] as String,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings,
                        color: AppTheme.accentColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Annual Savings',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${(tip['estimatedSavings'] as double).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tip['description'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textColor,
                    height: 1.6,
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
