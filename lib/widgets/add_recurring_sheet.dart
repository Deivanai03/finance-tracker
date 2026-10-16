import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/category.dart';
import '../models/recurring_expense.dart';
import '../services/category_service.dart';
import '../services/recurring_expense_service.dart';

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1: return '${n}st';
    case 2: return '${n}nd';
    case 3: return '${n}rd';
    default: return '${n}th';
  }
}

class AddRecurringSheet extends StatefulWidget {
  final RecurringExpense? existing;
  const AddRecurringSheet({super.key, this.existing});

  @override
  State<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<AddRecurringSheet> {
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  int? selectedCategoryId;
  late int selectedDay;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nameController = TextEditingController(text: e?.name ?? '');
    amountController = TextEditingController(text: e != null ? e.amount.toStringAsFixed(0) : '');
    selectedCategoryId = e?.categoryId;
    selectedDay = e?.dayOfMonth ?? 1;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    if (name.isEmpty || amount == null || selectedCategoryId == null) return;
    if (isEdit) {
      await RecurringExpenseService.update(
        key: widget.existing!.key as int,
        name: name, amount: amount,
        categoryId: selectedCategoryId!,
        dayOfMonth: selectedDay,
      );
    } else {
      await RecurringExpenseService.add(
        name: name, amount: amount,
        categoryId: selectedCategoryId!,
        dayOfMonth: selectedDay,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c ?? AC.accent.withValues(alpha: 0.3)),
      );

  @override
  Widget build(BuildContext context) {
    final categories = CategoryService.getAllCategories();
    return Container(
      decoration: BoxDecoration(
        color: AC.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.accent.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(isEdit ? 'Edit Recurring' : 'New Recurring',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            style: TextStyle(color: AC.text),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              hintText: 'e.g. Netflix, Rent',
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.dmSans(color: AC.accent, fontWeight: FontWeight.bold),
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AC.accent.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedCategoryId,
                isExpanded: true,
                hint: Text('Select category', style: GoogleFonts.inter(color: AC.textLight)),
                dropdownColor: AC.card,
                items: categories.map((Category c) => DropdownMenuItem(
                  value: c.key as int,
                  child: Text('${c.emoji} ${c.name}', style: GoogleFonts.inter(color: AC.text)),
                )).toList(),
                onChanged: (v) => setState(() => selectedCategoryId = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AC.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due every month on the', style: GoogleFonts.inter(color: AC.textLight, fontSize: 13)),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedDay,
                    dropdownColor: AC.card,
                    items: List.generate(28, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_ordinal(i + 1), style: GoogleFonts.dmSans(color: AC.text, fontWeight: FontWeight.bold)),
                    )),
                    onChanged: (v) => setState(() => selectedDay = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
              child: Text(isEdit ? 'Save Changes ✨' : 'Save ✨',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
            ),
          ),
        ],
      ),
    );
  }
}
