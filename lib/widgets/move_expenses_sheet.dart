import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';

class MoveExpensesSheet extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const MoveExpensesSheet({super.key, required this.categoryId, required this.categoryName});

  @override
  State<MoveExpensesSheet> createState() => _MoveExpensesSheetState();
}

class _MoveExpensesSheetState extends State<MoveExpensesSheet> {
  int? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categories = CategoryService.getAllCategories().where((c) => c.key != widget.categoryId).toList();

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
          Text('Move Expenses', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AC.text)),
          const SizedBox(height: 8),
          Text('Move all expenses from "${widget.categoryName}" to:', style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
          const SizedBox(height: 20),
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
                hint: Text('Select a category', style: GoogleFonts.inter(color: AC.textLight)),
                dropdownColor: AC.card,
                items: categories.map((Category c) => DropdownMenuItem<int>(
                  value: c.key as int,
                  child: Text('${c.emoji} ${c.name}', style: GoogleFonts.inter(color: AC.text)),
                )).toList(),
                onChanged: (v) => setState(() => selectedCategoryId = v),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: selectedCategoryId == null ? null : () async {
              await ExpenseService.reassignCategory(fromCategoryId: widget.categoryId, toCategoryId: selectedCategoryId!);
              await CategoryService.deleteCategory(widget.categoryId);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: selectedCategoryId != null
                    ? LinearGradient(colors: [AC.accent, AC.primary], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: selectedCategoryId == null ? AC.primary.withValues(alpha: 0.4) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: selectedCategoryId != null ? [BoxShadow(color: AC.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))] : null,
              ),
              alignment: Alignment.center,
              child: Text('Move & Delete', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: selectedCategoryId != null ? AC.text : AC.textLight)),
            ),
          ),
        ],
      ),
    );
  }
}
