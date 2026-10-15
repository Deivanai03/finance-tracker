import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/settings_service.dart';
import '../utils/format.dart';
import '../utils/transitions.dart';
import '../widgets/add_category_sheet.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/count_up_text.dart';
import 'category_details_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final AnimationController _heroController;
  late final Animation<double> _heroFade;
  late final ConfettiController _confettiCtrl;

  bool _reorderMode = false;
  // Ordered list of category keys; null = use default (most-used) sort
  List<int>? _customOrder;

  static const _lightCardColors = [
    Color(0xFFFDE8EE), Color(0xFFEADFFF), Color(0xFFDDEEE8),
    Color(0xFFFFF0D6), Color(0xFFD6EAFF), Color(0xFFFFE4F0),
  ];
  static const _darkCardColors = [
    Color(0xFF1E2235), Color(0xFF1A2030), Color(0xFF1C1F2E),
    Color(0xFF1E2235), Color(0xFF1A2030), Color(0xFF1C1F2E),
  ];
  List<Color> get _cardBgColors => themeNotifier.value ? _darkCardColors : _lightCardColors;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _heroController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));

    _customOrder = SettingsService.categoryOrder;

    final day = DateTime.now().day;
    if (day <= 3) {
      final budget = SettingsService.monthlyBudget;
      final prevTotal = ExpenseService.getPreviousMonthTotal();
      if (budget != null && prevTotal > 0 && prevTotal < budget) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _confettiCtrl.play();
        });
      }
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _heroController.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌸';
    return 'Good evening 🌙';
  }

  List<Category> _sortedCategories() {
    final all = CategoryService.getAllCategories();
    final order = _customOrder;

    if (order == null || order.isEmpty) {
      // Default: sort by most used in current cycle
      return all
        ..sort((a, b) => ExpenseService.getCurrentCycleCategoryTotal(b.key as int)
            .compareTo(ExpenseService.getCurrentCycleCategoryTotal(a.key as int)));
    }

    // Apply custom order; append any new categories not yet in the saved order
    final orderMap = {for (var i = 0; i < order.length; i++) order[i]: i};
    return all
      ..sort((a, b) {
        final ai = orderMap[a.key as int] ?? 999;
        final bi = orderMap[b.key as int] ?? 999;
        return ai.compareTo(bi);
      });
  }

  void _saveOrder(List<Category> categories) {
    final keys = categories.map((c) => c.key as int).toList();
    setState(() => _customOrder = keys);
    SettingsService.categoryOrder = keys;
  }

  void _resetToDefault() {
    setState(() {
      _customOrder = null;
      _reorderMode = false;
    });
    SettingsService.categoryOrder = null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, _, __) {
        final categories = _sortedCategories();
        final totalSpent = ExpenseService.getCurrentCycleTotal();
        final totalIncome = IncomeService.getCurrentCycleTotal();
        final budget = SettingsService.monthlyBudget;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AC.bg,
              body: SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  color: AC.accent,
                  backgroundColor: AC.card,
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    setState(() {});
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(totalSpent, totalIncome, budget)),
                      SliverToBoxAdapter(child: _buildInsights(totalSpent)),
                      if (_reorderMode)
                        SliverToBoxAdapter(child: _buildReorderBanner()),
                      if (_reorderMode)
                        SliverToBoxAdapter(
                          child: _buildReorderableGrid(categories),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == categories.length) return _buildAddCategoryCard();
                                return _buildCategoryCard(context, categories[index], index);
                              },
                              childCount: categories.length + 1,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 40,
                colors: [AC.accent, AC.success, AC.secondary, const Color(0xFFFFD700)],
                shouldLoop: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReorderBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AC.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AC.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_indicator_rounded, size: 18, color: AC.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Drag to reorder categories',
                style: GoogleFonts.inter(fontSize: 13, color: AC.text),
              ),
            ),
            GestureDetector(
              onTap: _resetToDefault,
              child: Text(
                'Reset',
                style: GoogleFonts.inter(fontSize: 12, color: AC.textLight, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _reorderMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AC.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Done', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.bg)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableGrid(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: animation.drive(Tween(begin: 1.0, end: 1.04)
                .chain(CurveTween(curve: Curves.easeOut))),
            child: child,
          ),
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildDraggableCategoryCard(context, category, index, key: ValueKey(category.key));
        },
        onReorderItem: (oldIndex, newIndex) {
          HapticFeedback.mediumImpact();
          final reordered = List<Category>.from(categories);
          final item = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, item);
          _saveOrder(reordered);
        },
      ),
    );
  }

  Widget _buildDraggableCategoryCard(BuildContext context, Category category, int index, {required Key key}) {
    final categoryId = category.key as int;
    final total = ExpenseService.getCurrentCycleCategoryTotal(categoryId);
    final bgColor = _cardBgColors[index % _cardBgColors.length];

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.6), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AC.text)),
                  const SizedBox(height: 2),
                  Text(fmtAmount(total), style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
                  if (category.budget != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (total / category.budget!).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AC.text.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                          total > category.budget! ? Colors.red[300]! : AC.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.drag_handle_rounded, color: AC.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double totalSpent, double totalIncome, double? budget) {
    final prevMonth = ExpenseService.getPreviousMonthTotal();
    final day = DateTime.now().day;
    final hasPrevData = prevMonth > 0;

    return FadeTransition(
      opacity: _heroFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting(), style: GoogleFonts.inter(fontSize: 14, color: AC.textLight)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Finance Tracker', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AC.text)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, fadeScaleRoute(const WishlistScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AC.secondary, borderRadius: BorderRadius.circular(14)),
                        child: const Text('🛍️', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context, fadeScaleRoute(const SettingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AC.secondary, borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.settings_rounded, size: 20, color: AC.textLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHeroCard(totalSpent, totalIncome, budget),
            if (day <= 3 && hasPrevData) ...[
              const SizedBox(height: 12),
              _buildMonthlySummary(prevMonth),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(double totalSpent, double totalIncome, double? budget) {
    final hasBudget = budget != null && budget > 0;
    final budgetProgress = hasBudget ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final overBudget = hasBudget && totalSpent > budget;

    final cycleStart = SettingsService.cycleStart;
    final cycleEnd = SettingsService.cycleEnd;
    final hasSalaryDate = SettingsService.salaryDate != null;
    final cycleLabel = hasSalaryDate
        ? '${DateFormat('dd MMM').format(cycleStart)} – ${DateFormat('dd MMM').format(cycleEnd)}'
        : 'This month';

    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AC.primary, AC.accent.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: AC.accent.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              ..._buildSparkles(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cycleLabel, style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
                  const SizedBox(height: 8),
                  CountUpText(
                    totalSpent,
                    style: GoogleFonts.dmSans(fontSize: 40, fontWeight: FontWeight.w600, color: AC.text),
                  ),
                  const SizedBox(height: 4),
                  Text('total spent', style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
                  if (hasBudget) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          overBudget ? '⚠️ Over budget' : 'Budget: ${fmtAmount(totalSpent)} / ${fmtAmount(budget)}',
                          style: GoogleFonts.inter(fontSize: 12, color: overBudget ? Colors.red[400] : AC.textLight),
                        ),
                        Text('${(budgetProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: overBudget ? Colors.red[400] : AC.textLight)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: budgetProgress,
                        minHeight: 6,
                        backgroundColor: AC.textLight.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(overBudget ? Colors.red[300]! : AC.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummary(double prevTotal) {
    final now = DateTime.now();
    final prevDate = DateTime(now.year, now.month - 1);
    final month = DateFormat('MMMM').format(prevDate);
    final budget = SettingsService.monthlyBudget;

    String message;
    String emoji;
    if (budget != null && budget > 0) {
      final diff = budget - prevTotal;
      if (diff >= 0) {
        message = '🎉 Saved ${fmtAmount(diff)} vs ${fmtAmount(budget)} budget';
        emoji = '✅';
      } else {
        message = 'Overspent ${fmtAmount(-diff)} vs ${fmtAmount(budget)} budget';
        emoji = '⚠️';
      }
    } else {
      message = 'You spent ${fmtAmount(prevTotal)}';
      emoji = '📊';
    }

    final prevCatTotals = ExpenseService.getPreviousMonthCategoryWiseTotals();
    String? topCatStr;
    if (prevCatTotals.isNotEmpty) {
      final topId = prevCatTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final topCat = CategoryService.getCategoryById(topId);
      if (topCat != null) topCatStr = '${topCat.emoji} Most on ${topCat.name}: ${fmtAmount(prevCatTotals[topId]!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AC.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AC.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last month ($month)', style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
                Text(message, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
                if (topCatStr != null) ...[
                  const SizedBox(height: 2),
                  Text(topCatStr, style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(double thisMonthTotal) {
    final budget = SettingsService.monthlyBudget;
    final prevMonthTotal = ExpenseService.getPreviousMonthTotal();

    String? insightText;

    if (budget != null && budget > 0 && thisMonthTotal > budget) {
      insightText = "You've gone over budget this month 😬";
    } else if (budget != null && budget > 0 && thisMonthTotal >= budget * 0.8) {
      insightText = "Getting close to your budget! Watch your spending 🔔";
    } else if (budget != null && budget > 0 && thisMonthTotal > 0 && thisMonthTotal < budget * 0.5) {
      insightText = "Great pace! You're well within budget 🎯";
    } else if (prevMonthTotal > 0) {
      // Check if top category this cycle is up vs last month
      final cycleCategories = CategoryService.getAllCategories();
      String? topCatName;
      double topCatTotal = 0;
      for (final cat in cycleCategories) {
        final t = ExpenseService.getCurrentCycleCategoryTotal(cat.key as int);
        if (t > topCatTotal) {
          topCatTotal = t;
          topCatName = cat.name;
        }
      }
      if (topCatName != null && topCatTotal > 0) {
        insightText = "Top category this cycle: $topCatName (${fmtAmount(topCatTotal)}) 📊";
      }
    }

    if (insightText == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AC.primary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(insightText, style: GoogleFonts.inter(fontSize: 13, color: AC.text))),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final rng = Random(42);
    return List.generate(5, (i) {
      final x = rng.nextDouble() * 250 + 120;
      final y = rng.nextDouble() * 60;
      final size = 8.0 + rng.nextDouble() * 10;
      return Positioned(
        right: x - 120,
        top: y,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (_, __) => Opacity(
            opacity: (0.3 + 0.5 * sin(_sparkleController.value * pi + i)).clamp(0.0, 1.0),
            child: Text('✦', style: TextStyle(fontSize: size, color: AC.accent.withValues(alpha: 0.6))),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryCard(BuildContext context, Category category, int index) {
    final categoryId = category.key as int;
    final total = ExpenseService.getCurrentCycleCategoryTotal(categoryId);
    final bgColor = _cardBgColors[index % _cardBgColors.length];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fadeScaleRoute(CategoryDetailsScreen(categoryId: categoryId, categoryName: category.name, emoji: category.emoji)),
      ).then((_) => setState(() {})),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        setState(() => _reorderMode = true);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.6), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Hero(
                  tag: 'emoji_$categoryId',
                  flightShuttleBuilder: (_, animation, __, fromContext, toContext) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (_, __) {
                        final size = Tween<double>(begin: 32, end: 64).evaluate(
                          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
                        );
                        return Material(
                          type: MaterialType.transparency,
                          child: Text(category.emoji, style: TextStyle(fontSize: size, decoration: TextDecoration.none)),
                        );
                      },
                    );
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(category.emoji, style: const TextStyle(fontSize: 32, decoration: TextDecoration.none)),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddExpenseSheet(categoryId: categoryId));
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AC.text.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.add, size: 16, color: AC.text),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(category.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AC.text)),
            const SizedBox(height: 4),
            Text(fmtAmount(total), style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w600, color: AC.text)),
            if (category.budget != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (total / category.budget!).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AC.text.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(total > category.budget! ? Colors.red[300]! : AC.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryCard() {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddCategorySheet());
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AC.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 32, color: AC.accent),
            const SizedBox(height: 8),
            Text('New Category', style: GoogleFonts.inter(fontSize: 13, color: AC.textLight, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
