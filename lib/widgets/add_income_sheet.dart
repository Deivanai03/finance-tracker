import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/income.dart';
import '../services/income_service.dart';

class AddIncomeSheet extends StatefulWidget {
  final Income? existing;
  const AddIncomeSheet({super.key, this.existing});

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  late final TextEditingController amountController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: widget.existing != null ? widget.existing!.amount.toStringAsFixed(0) : '');
    noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;
    final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
    if (widget.existing != null) {
      await IncomeService.update(key: widget.existing!.key as int, amount: amount, note: note);
    } else {
      await IncomeService.add(amount: amount, note: note);
    }
    if (mounted) Navigator.pop(context);
  }

  OutlineInputBorder _border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color ?? AC.accent.withValues(alpha: 0.3)),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: BoxDecoration(color: AC.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.accent.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(isEdit ? 'Edit Income' : 'New Income', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(color: AC.success.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
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
          TextField(
            controller: noteController,
            style: GoogleFonts.inter(color: AC.text),
            decoration: InputDecoration(
              hintText: 'Add a note... (optional)',
              hintStyle: GoogleFonts.inter(color: AC.textLight),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(AC.accent),
              filled: true,
              fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AC.accent, AC.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AC.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: Text(isEdit ? 'Update ✨' : 'Save ✨', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.text)),
            ),
          ),
        ],
      ),
    );
  }
}
