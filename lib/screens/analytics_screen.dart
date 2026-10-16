import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../utils/format.dart';
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



  @override
  Widget build(BuildContext context) {
    final monthTotal = ExpenseService.getMonthTotal(_selectedMonth);
    final avgDaily = ExpenseService.getAverageDailySpendForMonth(_selectedMonth);
    final highestDay = ExpenseService.getHighestSpendDayForMonth(_selectedMonth);
    final topCategoryId = ExpenseService.getTopCategoryIdForMonth(_selectedMonth);
    final topCategory = topCategoryId == -1 ? null : CategoryService.getCategoryById(topCategoryId);

    final categoryIdTotals = ExpenseService.getCategoryWiseTotalsForMonth(_selectedMonth);
    final dailyTotals = ExpenseService.getDailySpendingForMonth(_selectedMonth);

    final entries = categoryIdTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
                    color: const Color(0xFFC77DFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
              Expanded(child: _statCard('Total Spent', monthTotal, const Color(0xFFC77DFF))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Avg / Day', avgDaily, const Color(0xFFFFD93D))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('Highest Day', highestDay, const Color(0xFFFF6B6B))),
              const SizedBox(width: 12),
              Expanded(child: _topCatCard(topCategory == null ? 'None' : '${topCategory.emoji} ${topCategory.name}')),
            ]),

            if (entries.isEmpty) ...[
              const SizedBox(height: 60),
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🌸', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('No expenses this month', style: GoogleFonts.inter(color: AC.textLight, fontSize: 15)),
              ])),
            ] else ...[
              const SizedBox(height: 32),
              Text('Where it went', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
              const SizedBox(height: 16),
              _buildStackedBar(entries, monthTotal),
              const SizedBox(height: 32),
              Text('Daily spend', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
              const SizedBox(height: 16),
              BarChartWidget(totals: dailyTotals),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStackedBar(List<MapEntry<int, double>> entries, double totalSpend) {
    final top5 = entries.take(5).toList();
    final total = top5.fold(0.0, (s, e) => s + e.value);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 14,
            child: Row(
              children: top5.asMap().entries.map((e) {
                final fraction = e.value.value / total;
                final color = AppColors.cardColors[e.key % AppColors.cardColors.length];
                return Flexible(
                  flex: (fraction * 1000).round(),
                  child: Container(color: color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        ...top5.asMap().entries.map((e) {
          final cat = CategoryService.getCategoryById(e.value.key);
          final color = AppColors.cardColors[e.key % AppColors.cardColors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat != null ? '${cat.emoji} ${cat.name}' : 'Unknown',
                    style: GoogleFonts.inter(fontSize: 13, color: AC.text),
                  ),
                ),
                Text(
                  fmtAmount(e.value.value),
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AC.text),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statCard(String title, double value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          CountUpText(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _topCatCard(String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6BCB77),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Category', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
