import 'dart:ui';

import 'package:flutter/material.dart';

import '../main.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'manage_recurring_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;

  final _screens = const [HomeScreen(), HistoryScreen(), AnalyticsScreen(), ManageRecurringScreen()];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          extendBody: true,
          body: _screens[_index],
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: AC.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: AC.accent.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(icon: Icons.home_rounded, label: 'Home', selected: _index == 0, onTap: () => setState(() => _index = 0)),
                      _NavItem(icon: Icons.receipt_long_rounded, label: 'History', selected: _index == 1, onTap: () => setState(() => _index = 1)),
                      _NavItem(icon: Icons.auto_graph_rounded, label: 'Analytics', selected: _index == 2, onTap: () => setState(() => _index = 2)),
                      _NavItem(icon: Icons.repeat_rounded, label: 'Recurring', selected: _index == 3, onTap: () => setState(() => _index = 3)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AC.accent.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AC.text : AC.textLight, size: 22),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: AC.text, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
