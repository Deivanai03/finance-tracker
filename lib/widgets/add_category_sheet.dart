import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/category_service.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final emojiController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    emojiController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final emoji = emojiController.text.trim();
    final name = nameController.text.trim();
    if (emoji.isEmpty || name.isEmpty) return;
    await CategoryService.addCategory(name: name, emoji: emoji);
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
          Text('New Category', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
          const SizedBox(height: 28),
          TextField(
            controller: emojiController,
            style: GoogleFonts.inter(fontSize: 24, color: AC.text),
            decoration: InputDecoration(
              labelText: 'Icon',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              hintText: '😀',
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(AC.accent),
              filled: true,
              fillColor: AC.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            style: GoogleFonts.inter(color: AC.text),
            decoration: InputDecoration(
              labelText: 'Category Name',
              labelStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 13),
              hintText: 'e.g. Skincare',
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
                color: AC.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text('Create ✨', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
            ),
          ),
        ],
      ),
    );
  }
}
