import 'package:flutter/material.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/features/watchlist/screens/watchlist_screen.dart';
import 'package:trading_app/features/markets/screens/markets_screen.dart';
import 'package:trading_app/features/holdings/screens/holdings_screen.dart';
import 'package:trading_app/features/settings/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WatchlistScreen(),
    const MarketsScreen(),
    const HoldingsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded),
              activeIcon: Icon(Icons.star_rounded, color: AppColors.primary),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_rounded),
              activeIcon: Icon(Icons.work_rounded, color: AppColors.primary),
              label: 'Holdings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
