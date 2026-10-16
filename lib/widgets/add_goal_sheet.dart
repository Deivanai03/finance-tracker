import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/savings_goal.dart';
import '../services/savings_goal_service.dart';

class AddGoalSheet extends StatefulWidget {
  final SavingsGoal? existing;
  const AddGoalSheet({super.key, this.existing});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late final TextEditingController emojiController;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nameController = TextEditingController(text: e?.name ?? '');
    amountController = TextEditingController(text: e != null ? e.targetAmount.toStringAsFixed(0) : '');
    emojiController = TextEditingController(text: e?.emoji ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    emojiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final emoji = emojiController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    if (name.isEmpty || emoji.isEmpty || amount == null || amount <= 0) return;
    if (isEdit) {
      await SavingsGoalService.update(key: widget.existing!.key as int, name: name, emoji: emoji, targetAmount: amount);
    } else {
      await SavingsGoalService.add(name: name, emoji: emoji, targetAmount: amount);
    }
    if (mounted) Navigator.pop(context);
  }

  OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c ?? AC.accent.withValues(alpha: 0.3)),
      );

  @override
  Widget build(BuildContext context) {
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
          Text(isEdit ? 'Edit Goal' : 'New Goal ✨',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
          const SizedBox(height: 24),
          TextField(
            controller: emojiController,
            style: TextStyle(fontSize: 24, color: AC.text),
            decoration: InputDecoration(
              labelText: 'Icon',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            style: TextStyle(color: AC.text),
            decoration: InputDecoration(
              labelText: 'What do you want?',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              hintText: 'e.g. New iPhone, Vacation',
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AC.text),
            decoration: InputDecoration(
              labelText: 'Target Amount',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.dmSans(color: AC.accent, fontWeight: FontWeight.bold),
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
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
                color: AC.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(isEdit ? 'Save Changes ✨' : 'Add to Wishlist ✨',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
            ),
          ),
        ],
      ),
    );
  }
}
