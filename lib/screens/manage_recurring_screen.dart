import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/recurring_expense.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/recurring_expense_service.dart';
import '../widgets/add_recurring_sheet.dart';

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1: return '${n}st';
    case 2: return '${n}nd';
    case 3: return '${n}rd';
    default: return '${n}th';
  }
}

class ManageRecurringScreen extends StatefulWidget {
  const ManageRecurringScreen({super.key});

  @override
  State<ManageRecurringScreen> createState() => _ManageRecurringScreenState();
}

class _ManageRecurringScreenState extends State<ManageRecurringScreen> {
  @override
  Widget build(BuildContext context) {
    final due = RecurringExpenseService.getDueSoon();
    final all = RecurringExpenseService.getAll();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recurring', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AC.text)),
                GestureDetector(
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddRecurringSheet(),
                    );
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AC.accent, AC.primary]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 16, color: AC.text),
                        const SizedBox(width: 4),
                        Text('Add', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AC.text)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Due Soon section
            if (due.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Due Soon 🔔', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
              const SizedBox(height: 12),
              ...due.map((r) => _buildDueCard(r, now)),
            ],

            // All recurring
            const SizedBox(height: 24),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔄', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No recurring expenses yet', style: GoogleFonts.inter(color: AC.textLight, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Tap Add to create one', style: GoogleFonts.inter(color: AC.textLight, fontSize: 13)),
                  ]),
                ),
              )
            else
              ...all.map((r) => _buildAllCard(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildDueCard(RecurringExpense r, DateTime now) {
    final cat = CategoryService.getCategoryById(r.categoryId);
    final isOverdue = r.dayOfMonth < now.day;
    final isToday = r.dayOfMonth == now.day;

    return Dismissible(
      key: ValueKey('due_${r.key}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) async {
        await RecurringExpenseService.markPaid(r.key as int);
        await ExpenseService.addExpense(amount: r.amount, categoryId: r.categoryId, note: r.name);
        setState(() {});
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AC.success.withValues(alpha: 0.8), AC.success.withValues(alpha: 0.3)]),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AC.bg, size: 26),
            const SizedBox(width: 8),
            Text('Mark Paid', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AC.bg, fontSize: 14)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isOverdue ? const Color(0xFFFFE4E4) : AC.secondary.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Text(cat?.emoji ?? '🔄', style: const TextStyle(fontSize: 26)),
          title: Text(r.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AC.text)),
          subtitle: Text(
            isOverdue ? 'Overdue · ${_ordinal(r.dayOfMonth)} of the month' : isToday ? 'Due today' : 'Due on the ${_ordinal(r.dayOfMonth)}',
            style: GoogleFonts.inter(fontSize: 12, color: isOverdue ? Colors.red[400] : AC.textLight),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${r.amount.toStringAsFixed(0)}', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AC.text, fontSize: 15)),
              const SizedBox(width: 10),
              Icon(Icons.swipe_rounded, size: 16, color: AC.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    HapticFeedback.mediumImpact();
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AC.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete "$name"?', style: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.bold)),
            content: Text('This recurring expense will be removed.', style: GoogleFonts.inter(color: AC.textLight)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.inter(color: AC.textLight)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: GoogleFonts.inter(color: Colors.red[400], fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildAllCard(RecurringExpense r) {
    final cat = CategoryService.getCategoryById(r.categoryId);
    final paidThisMonth = r.lastPaidAt != null &&
        r.lastPaidAt!.year == DateTime.now().year &&
        r.lastPaidAt!.month == DateTime.now().month;

    return Dismissible(
      key: ValueKey('all_${r.key}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, r.name),
      onDismissed: (_) async {
        await RecurringExpenseService.delete(r.key as int);
        setState(() {});
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.red[400], fontSize: 14)),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 24),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AC.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AC.primary.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AC.primary, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(cat?.emoji ?? '🔄', style: const TextStyle(fontSize: 22)),
          ),
          title: Text(r.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AC.text)),
          subtitle: Text(
            '${cat?.name ?? ''} · Every month on the ${_ordinal(r.dayOfMonth)}',
            style: GoogleFonts.inter(fontSize: 12, color: AC.textLight),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${r.amount.toStringAsFixed(0)}', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AC.text, fontSize: 15)),
                  if (paidThisMonth) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AC.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AC.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 10, color: AC.success),
                          const SizedBox(width: 3),
                          Text('Paid', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AC.success)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddRecurringSheet(existing: r),
                  );
                  setState(() {});
                },
                child: Icon(Icons.edit_rounded, color: AC.textLight, size: 18),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final confirmed = await _confirmDelete(context, r.name);
                  if (confirmed) {
                    await RecurringExpenseService.delete(r.key as int);
                    setState(() {});
                  }
                },
                child: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}