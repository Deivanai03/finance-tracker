import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../utils/format.dart';
enum _SortOrder { dateDesc, dateAsc, amountDesc, amountAsc }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? selectedCategoryId;
  String selectedMonth = 'All';
  String searchQuery = '';
  String? selectedTag;
  _SortOrder sortOrder = _SortOrder.dateDesc;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryService.getAllCategories();
    final allExpenses = ExpenseService.getAllExpensesSorted();

    final months = ['All', ...allExpenses.map((e) => DateFormat('MMMM yyyy').format(e.createdAt)).toSet()];

    // Collect all unique tags
    final allTags = <String>{};
    for (final e in allExpenses) {
      allTags.addAll(parseTags(e.note));
    }

    var filtered = allExpenses.where((expense) {
      final catMatch = selectedCategoryId == null || expense.categoryId == selectedCategoryId;
      if (!catMatch) return false;
      if (selectedMonth != 'All' && DateFormat('MMMM yyyy').format(expense.createdAt) != selectedMonth) return false;
      if (selectedTag != null && !parseTags(expense.note).contains(selectedTag)) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final note = expense.note?.toLowerCase() ?? '';
        final cat = CategoryService.getCategoryById(expense.categoryId);
        final catName = cat?.name.toLowerCase() ?? '';
        if (!note.contains(q) && !catName.contains(q)) return false;
      }
      return true;
    }).toList();

    // Sort
    switch (sortOrder) {
      case _SortOrder.dateDesc: filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOrder.dateAsc: filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOrder.amountDesc: filtered.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortOrder.amountAsc: filtered.sort((a, b) => a.amount.compareTo(b.amount));
    }

    final total = filtered.fold(0.0, (sum, e) => sum + e.amount);

    // Group by date (only for date sorts)
    final bool isDateSort = sortOrder == _SortOrder.dateDesc || sortOrder == _SortOrder.dateAsc;
    final Map<String, List<Expense>> grouped = {};
    for (final e in filtered) {
      final key = isDateSort ? DateFormat('dd MMMM yyyy').format(e.createdAt) : 'All';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('History', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AC.text)),
                  _sortButton(),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => searchQuery = v),
                style: GoogleFonts.inter(color: AC.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by note or category…',
                  hintStyle: GoogleFonts.inter(color: AC.textLight, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: AC.textLight, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _searchController.clear(); setState(() => searchQuery = ''); },
                          child: Icon(Icons.close_rounded, color: AC.textLight, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AC.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            // Filters row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _dropdown<int?>(
                    value: selectedCategoryId,
                    hint: 'All categories',
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text('All', style: GoogleFonts.inter(color: AC.text))),
                      ...categories.map((Category c) => DropdownMenuItem<int?>(
                            value: c.key as int,
                            child: Text('${c.emoji} ${c.name}', style: GoogleFonts.inter(color: AC.text)),
                          )),
                    ],
                    onChanged: (v) => setState(() => selectedCategoryId = v),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _dropdown<String>(
                    value: selectedMonth,
                    hint: 'Month',
                    items: months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(color: AC.text, fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => selectedMonth = v!),
                  )),
                ],
              ),
            ),
            // Tag filter chips
            if (allTags.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: allTags.map((tag) {
                    final selected = selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTag = selected ? null : tag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected ? AC.accent : AC.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? AC.accent : AC.accent.withValues(alpha: 0.3)),
                          ),
                          child: Text('#$tag', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AC.text : AC.textLight)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Total bar
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AC.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${filtered.length} expense${filtered.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
                      Text(fmtAmount(total),
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.bold, color: AC.text)),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🌸', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Nothing here yet', style: GoogleFonts.inter(color: AC.textLight, fontSize: 16)),
                      ]),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isDateSort)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                                child: Row(children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AC.accent, borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(width: 8),
                                  Text(entry.key, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AC.textLight)),
                                ]),
                              ),
                            ...entry.value.map((expense) => _buildTile(expense)),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortButton() {
    final labels = {
      _SortOrder.dateDesc: 'Date ↓',
      _SortOrder.dateAsc: 'Date ↑',
      _SortOrder.amountDesc: 'Amount ↓',
      _SortOrder.amountAsc: 'Amount ↑',
    };
    return GestureDetector(
      onTap: () {
        final orders = _SortOrder.values;
        setState(() => sortOrder = orders[(orders.indexOf(sortOrder) + 1) % orders.length]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AC.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(labels[sortOrder]!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.text)),
      ),
    );
  }

  Widget _dropdown<T>({required T value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.accent.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.inter(color: AC.textLight, fontSize: 13)),
          items: items,
          onChanged: onChanged,
          dropdownColor: AC.card,
        ),
      ),
    );
  }

  Widget _buildTile(Expense expense) {
    final category = CategoryService.getCategoryById(expense.categoryId);
    final key = expense.key as int;

    return Dismissible(
      key: ValueKey(key),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AC.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete expense?', style: GoogleFonts.outfit(color: AC.text, fontWeight: FontWeight.bold)),
            content: Text('This cannot be undone.', style: GoogleFonts.inter(color: AC.textLight)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        await ExpenseService.deleteExpense(key);
        setState(() {});
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AC.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AC.primary.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AC.primary, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(category?.emoji ?? '💰', style: const TextStyle(fontSize: 22)),
          ),
          title: Text(fmtAmount(expense.amount), style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AC.text, fontSize: 16)),
          subtitle: Text(
            [category?.name ?? 'Unknown', if (expense.note?.isNotEmpty == true) expense.note!].join(' · '),
            style: GoogleFonts.inter(color: AC.textLight, fontSize: 12),
          ),
          trailing: Text(DateFormat('hh:mm a').format(expense.createdAt), style: GoogleFonts.inter(fontSize: 11, color: AC.textLight)),
        ),
      ),
    );
  }
}
