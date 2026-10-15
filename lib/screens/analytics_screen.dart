import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/count_up_text.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _selectedMonth;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(_now.year, _now.month);
  }

  bool get _isCurrentMonth => _selectedMonth.year == _now.year && _selectedMonth.month == _now.month;

  void _prevMonth() => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  void _nextMonth() {
    if (!_isCurrentMonth) setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  static const _lightTints = [
    Color(0xFFFDE8EE), Color(0xFFEADFFF), Color(0xFFDDEEE8),
    Color(0xFFFFF0D6), Color(0xFFD6EAFF), Color(0xFFFFE4F0),
  ];
  static const _darkTints = [
    Color(0xFF1E2235), Color(0xFF1A2030), Color(0xFF1C1F2E),
    Color(0xFF1E2235), Color(0xFF1A2030), Color(0xFF1C1F2E),
  ];
  List<Color> get _pastelTints => themeNotifier.value ? _darkTints : _lightTints;

  @override
  Widget build(BuildContext context) {
    final monthTotal = ExpenseService.getMonthTotal(_selectedMonth);
    final avgDaily = ExpenseService.getAverageDailySpendForMonth(_selectedMonth);

    final categoryIdTotals = ExpenseService.getCategoryWiseTotalsForMonth(_selectedMonth);
    final dailyTotals = ExpenseService.getDailySpendingForMonth(_selectedMonth);

    final entries = categoryIdTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxTotal = entries.isEmpty ? 1.0 : entries.first.value;

    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text('Analytics', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AC.text)),
            const SizedBox(height: 16),

            // Month picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _prevMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.chevron_left_rounded, color: AC.text, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AC.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AC.text),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isCurrentMonth ? null : _nextMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.chevron_right_rounded, color: _isCurrentMonth ? AC.textLight : AC.text, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stat cards row
            Row(children: [
              Expanded(child: _statCard('Total Spent', monthTotal, AC.primary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Avg / Day', avgDaily, AC.primary)),
            ]),

            if (entries.isEmpty) ...[
              const SizedBox(height: 60),
              const Center(child: Column(children: [
                SizedBox(height: 60),
                Text('🌸', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
              ])),
              Center(child: Text('No expenses this month', style: GoogleFonts.inter(color: AC.textLight, fontSize: 15))),
            ] else ...[
              const SizedBox(height: 32),
              Text('Spending by Category', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AC.text)),
              const SizedBox(height: 16),
              _buildBubbleChart(entries, maxTotal),
              const SizedBox(height: 32),
              Text('Daily Spending', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AC.text)),
              const SizedBox(height: 16),
              BarChartWidget(totals: dailyTotals),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleChart(List<MapEntry<int, double>> entries, double maxTotal) {
    final rng = Random(99);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: entries.asMap().entries.map((e) {
        final idx = e.key;
        final entry = e.value;
        final cat = CategoryService.getCategoryById(entry.key);
        final ratio = (entry.value / maxTotal).clamp(0.3, 1.0);
        final size = 70.0 + ratio * 90.0;
        final color = _pastelTints[rng.nextInt(_pastelTints.length)];
        return AnimatedBubble(
          size: size,
          color: color,
          emoji: cat?.emoji ?? '💰',
          name: cat?.name ?? '',
          amount: entry.value,
          delay: Duration(milliseconds: idx * 80),
        );
      }).toList(),
    );
  }

  Widget _statCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
          const SizedBox(height: 6),
          CountUpText(value, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
        ],
      ),
    );
  }
}

class AnimatedBubble extends StatefulWidget {
  final double size;
  final Color color;
  final String emoji;
  final String name;
  final double amount;
  final Duration delay;

  const AnimatedBubble({super.key, required this.size, required this.color, required this.emoji, required this.name, required this.amount, required this.delay});

  @override
  State<AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<AnimatedBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emoji, style: TextStyle(fontSize: widget.size * 0.28)),
            const SizedBox(height: 2),
            Text('₹${widget.amount.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(fontSize: widget.size * 0.13, fontWeight: FontWeight.w600, color: AC.text),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (widget.size > 90)
              Text(widget.name,
                  style: GoogleFonts.inter(fontSize: widget.size * 0.10, color: AC.textLight),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
