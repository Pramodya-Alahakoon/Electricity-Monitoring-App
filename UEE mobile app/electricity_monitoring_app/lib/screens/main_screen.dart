import 'package:electricity_monitoring_app/screens/dashboard/new_dashbaord_screen.dart';
import 'package:flutter/material.dart';
import 'settings/new_settings_screen.dart';
import 'budget/new_budget_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'analysis/budget_analysis_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Old Screen
  // final List<Widget> _pages = [
  //   const DashboardScreen(),
  //   const ApplianceListScreen(),
  //   const BudgetScreen(),
  //   const SettingsScreen(),
  // ];

  //New Screens
  final List<Widget> _pages = [
    const NewDashboardScreen(),
    const NewBudgetScreen(showBackButton: false),
    const BudgetAnalysisScreen(showBackButton: false),
    const LeaderboardScreen(),
    const NewSettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
