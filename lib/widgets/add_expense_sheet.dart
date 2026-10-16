import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class AddExpenseSheet extends StatefulWidget {
  final int categoryId;
  final Expense? expense;

  const AddExpenseSheet({super.key, required this.categoryId, this.expense});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      amountController.text = widget.expense!.amount.toString();
      noteController.text = widget.expense!.note ?? '';
      _selectedDate = widget.expense!.createdAt;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AC.accent,
            onPrimary: AC.text,
            surface: AC.card,
            onSurface: AC.text,
          ),
          dialogTheme: DialogThemeData(backgroundColor: AC.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      // Preserve the original time-of-day when editing, use noon for new picks
      final original = _selectedDate ?? now;
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          original.hour,
          original.minute,
          original.second,
        );
      });
    }
  }

  Future<void> _save() async {
    final text = amountController.text.trim();
    if (text.isEmpty) return;
    final amount = double.tryParse(text);
    if (amount == null) return;
    if (widget.expense == null) {
      await ExpenseService.addExpense(
        amount: amount,
        categoryId: widget.categoryId,
        note: noteController.text.trim(),
      );
    } else {
      await ExpenseService.updateExpense(
        key: widget.expense!.key as int,
        amount: amount,
        categoryId: widget.categoryId,
        note: noteController.text.trim(),
        createdAt: _selectedDate,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  OutlineInputBorder _border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color ?? AC.accent.withValues(alpha: 0.3)),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 32;
    return Container(
      decoration: BoxDecoration(
        color: AC.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      // Let the sheet grow to show all fields, capped at 85% screen height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AC.accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isEdit ? 'Edit Expense' : 'New Expense',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text),
            ),
            const SizedBox(height: 28),
            // Amount field
            Container(
              decoration: BoxDecoration(
                color: AC.card,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: !isEdit,
                style: GoogleFonts.dmSans(fontSize: 40, fontWeight: FontWeight.bold, color: AC.text),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.dmSans(fontSize: 40, fontWeight: FontWeight.bold, color: AC.accent),
                  hintText: '0',
                  hintStyle: GoogleFonts.dmSans(fontSize: 40, color: AC.accent.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Note field
            TextField(
              controller: noteController,
              style: GoogleFonts.inter(color: AC.text),
              decoration: InputDecoration(
                hintText: 'Add a note…',
                hintStyle: GoogleFonts.inter(color: AC.textLight),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(AC.accent),
                filled: true,
                fillColor: AC.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            // Date picker — always visible in edit mode
            if (isEdit) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AC.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AC.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: AC.accent),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                            : 'Select date',
                        style: GoogleFonts.inter(color: AC.text, fontSize: 15),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, size: 20, color: AC.textLight),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Save button
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: AC.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  isEdit ? 'Update ✨' : 'Save ✨',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.textOnVivid),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
