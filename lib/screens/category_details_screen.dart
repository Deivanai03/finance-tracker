import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../utils/format.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/edit_category_sheet.dart';
import '../widgets/move_expenses_sheet.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String emoji;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.emoji,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> with SingleTickerProviderStateMixin {
  late String categoryName;
  late String emoji;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    categoryName = widget.categoryName;
    emoji = widget.emoji;
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _deleteCategory() async {
    final total = ExpenseService.getCategoryTotal(widget.categoryId);
    if (total > 0) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _styledDialog(
          title: 'Cannot Delete',
          content: 'This category has expenses.',
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final moved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MoveExpensesSheet(categoryId: widget.categoryId, categoryName: categoryName),
                );
                if (moved == true && mounted) Navigator.pop(context);
              },
              child: const Text('Move Expenses'),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _styledDialog(
        title: 'Delete "$categoryName"?',
        content: 'This cannot be undone.',
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
        ],
      ),
    );
    if (ok == true) {
      await CategoryService.deleteCategory(widget.categoryId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteExpense(int key) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _styledDialog(
        title: 'Delete expense?',
        content: 'This cannot be undone.',
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ExpenseService.deleteExpense(key);
      setState(() {});
    }
  }

  Widget _styledDialog({required String title, required String content, required List<Widget> actions}) {
    return AlertDialog(
      backgroundColor: AC.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: GoogleFonts.outfit(color: AC.text, fontWeight: FontWeight.bold)),
      content: Text(content, style: GoogleFonts.inter(color: AC.textLight)),
      actions: actions,
    );
  }

  static const _lightTints = [
    Color(0xFFFDE8EE), Color(0xFFEADFFF), Color(0xFFDDEEE8),
    Color(0xFFFFF0D6), Color(0xFFD6EAFF), Color(0xFFFFE4F0),
  ];
  static const _darkTints = [
    Color(0xFF1E0A2E), Color(0xFF1E0A2E), Color(0xFF1E0A2E),
    Color(0xFF1E0A2E), Color(0xFF1E0A2E), Color(0xFF1E0A2E),
  ];
  List<Color> get _pastelTints => themeNotifier.value ? _darkTints : _lightTints;

  @override
  Widget build(BuildContext context) {
    final monthTotal = ExpenseService.getCurrentMonthCategoryTotal(widget.categoryId);
    final todayTotal = ExpenseService.getTodayCategoryTotal(widget.categoryId);
    final expenses = ExpenseService.getExpensesByCategory(widget.categoryId);
    final rng = Random(42);

    return Scaffold(
      backgroundColor: AC.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: AC.primary,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: AC.text),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_rounded, color: AC.text, size: 20),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EditCategorySheet(
                      id: widget.categoryId,
                      name: categoryName,
                      emoji: emoji,
                      budget: CategoryService.getCategoryById(widget.categoryId)?.budget,
                    ),
                  );
                  final updated = CategoryService.getCategoryById(widget.categoryId);
                  if (updated != null) setState(() { categoryName = updated.name; emoji = updated.emoji; });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 20),
                onPressed: _deleteCategory,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AC.primary, AC.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, -6 * _floatController.value),
                        child: Hero(
                          tag: 'emoji_${widget.categoryId}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(emoji, style: const TextStyle(fontSize: 64, decoration: TextDecoration.none)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(categoryName, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _statCard('This Month', fmtAmount(monthTotal), AC.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Today', fmtAmount(todayTotal), AC.secondary)),
                    ],
                  ),
                  Builder(builder: (_) {
                    final cat = CategoryService.getCategoryById(widget.categoryId);
                    if (cat?.budget == null) return const SizedBox.shrink();
                    final budget = cat!.budget!;
                    final progress = (monthTotal / budget).clamp(0.0, 1.0);
                    final overBudget = monthTotal > budget;
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: overBudget ? const Color(0xFFFFE4E4) : AC.success.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Monthly Budget', style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
                                Text('${fmtAmount(monthTotal)} / ${fmtAmount(budget)}',
                                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: overBudget ? Colors.red[400] : AC.text)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.6),
                                valueColor: AlwaysStoppedAnimation(overBudget ? Colors.red[300]! : AC.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          expenses.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No expenses yet', style: GoogleFonts.inter(color: AC.textLight, fontSize: 16)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddExpenseSheet(categoryId: widget.categoryId),
                            );
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AC.accent, AC.primary]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Add first expense', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AC.text)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = expenses[index];
                        final expenseKey = expense.key as int;
                        final tint = _pastelTints[rng.nextInt(_pastelTints.length)];
                        return _buildExpenseCard(expense, expenseKey, tint);
                      },
                      childCount: expenses.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.lightImpact();
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddExpenseSheet(categoryId: widget.categoryId),
          );
          setState(() {});
        },
        backgroundColor: AC.accent,
        icon: Icon(Icons.add, color: AC.text),
        label: Text('Add Expense', style: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, int expenseKey, Color tint) {
    return Dismissible(
      key: ValueKey(expenseKey),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => _styledDialog(
            title: 'Delete expense?',
            content: 'This cannot be undone.',
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) async {
        await ExpenseService.deleteExpense(expenseKey);
        setState(() {});
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 26),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmtAmount(expense.amount), style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
                    if (expense.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(expense.note!, style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormat('dd MMM').format(expense.createdAt), style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(Icons.edit_rounded, () async {
                        HapticFeedback.lightImpact();
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddExpenseSheet(categoryId: widget.categoryId, expense: expense),
                        );
                        setState(() {});
                      }),
                      const SizedBox(width: 8),
                      _iconBtn(Icons.delete_outline_rounded, () => _deleteExpense(expenseKey), isDelete: true),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool isDelete = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: isDelete ? Colors.red[300] : AC.text),
      ),
    );
  }
}
