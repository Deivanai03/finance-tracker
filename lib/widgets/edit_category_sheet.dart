import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/category_service.dart';

class EditCategorySheet extends StatefulWidget {
  final int id;
  final String name;
  final String emoji;
  final double? budget;

  const EditCategorySheet({super.key, required this.id, required this.name, required this.emoji, this.budget});

  @override
  State<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<EditCategorySheet> {
  TextEditingController? emojiController;
  TextEditingController? nameController;
  TextEditingController? budgetController;

  @override
  void initState() {
    super.initState();
    emojiController = TextEditingController(text: widget.emoji);
    nameController = TextEditingController(text: widget.name);
    budgetController = TextEditingController(text: widget.budget != null ? widget.budget!.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    emojiController?.dispose();
    nameController?.dispose();
    budgetController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final emoji = emojiController?.text.trim() ?? '';
    final name = nameController?.text.trim() ?? '';
    if (emoji.isEmpty || name.isEmpty) return;
    final budgetText = budgetController?.text.trim() ?? '';
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);
    await CategoryService.updateCategory(id: widget.id, name: name, emoji: emoji, budget: budget);
    if (mounted) Navigator.pop(context);
  }

  OutlineInputBorder _border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color ?? AC.accent.withValues(alpha: 0.3)),
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
          Text('Edit Category', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
          const SizedBox(height: 28),
          TextField(
            controller: emojiController,
            style: const TextStyle(fontSize: 24, color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Icon',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Category Name',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              border: _border(), enabledBorder: _border(), focusedBorder: _border(AC.accent),
              filled: true, fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Monthly Budget (optional)',
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
                gradient: LinearGradient(colors: [AC.accent, AC.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AC.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: Text('Save Changes ✨', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.text)),
            ),
          ),
        ],
      ),
    );
  }
}
