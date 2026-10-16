import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/income.dart';
import '../services/income_service.dart';
import '../services/settings_service.dart';
import '../utils/format.dart';
import '../widgets/add_income_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    final b = SettingsService.monthlyBudget;
    _budgetController = TextEditingController(text: b != null ? b.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final text = _budgetController.text.trim();
    if (text.isEmpty) {
      SettingsService.monthlyBudget = null;
    } else {
      final val = double.tryParse(text);
      if (val != null && val > 0) SettingsService.monthlyBudget = val;
    }
    FocusScope.of(context).unfocus();
  }

  void _pickSalaryDate() {
    final current = SettingsService.salaryDate;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalaryDatePicker(
        current: current,
        onSelected: (day) {
          SettingsService.salaryDate = day;
          setState(() {});
        },
        onCleared: () {
          SettingsService.salaryDate = null;
          setState(() {});
        },
      ),
    );
  }

  Future<void> _addOrEditIncome([Income? existing]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIncomeSheet(existing: existing),
    );
    setState(() {});
  }

  Future<void> _deleteIncome(int key) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AC.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete income?', style: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.bold)),
        content: Text('This cannot be undone.', style: GoogleFonts.inter(color: AC.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
        ],
      ),
    );
    if (ok == true) {
      await IncomeService.delete(key);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomes = IncomeService.getAll();
    final now = DateTime.now();
    final thisMonthIncomes = incomes.where((i) => i.createdAt.year == now.year && i.createdAt.month == now.month).toList();

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AC.bg,
          appBar: AppBar(
            backgroundColor: AC.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AC.text, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Settings', style: GoogleFonts.outfit(color: AC.text, fontWeight: FontWeight.bold, fontSize: 22)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _SectionLabel('Appearance'),
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                label: 'Dark Mode',
                trailing: Switch(
                  value: isDark,
                  activeColor: AC.accent,
                  onChanged: (value) {
                    themeNotifier.value = value;
                    SettingsService.isDarkMode = value;
                  },
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Budget'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: AC.accent, size: 22),
                    const SizedBox(width: 14),
                    Text('Monthly Budget', style: GoogleFonts.inter(color: AC.text, fontSize: 15)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSubmitted: (_) => _saveBudget(),
                        onTapOutside: (_) => _saveBudget(),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.bold, color: AC.text),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          prefixStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.bold, color: AC.accent),
                          hintText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_budgetController.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _budgetController.clear();
                          SettingsService.monthlyBudget = null;
                          setState(() {});
                        },
                        child: Icon(Icons.close_rounded, color: AC.textLight, size: 18),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Salary date tile
              GestureDetector(
                onTap: _pickSalaryDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.event_repeat_rounded, color: AC.accent, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Salary Date', style: GoogleFonts.inter(color: AC.text, fontSize: 15)),
                            Text(
                              'Home screen resets on this day each month',
                              style: GoogleFonts.inter(color: AC.textLight, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(builder: (_) {
                        final d = SettingsService.salaryDate;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (d != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AC.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AC.accent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _ordinal(d),
                                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: AC.accent),
                                ),
                              )
                            else
                              Text('Not set', style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, size: 18, color: AC.textLight),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel('Income This Month'),
                  GestureDetector(
                    onTap: () => _addOrEditIncome(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AC.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(Icons.add, size: 14, color: AC.textOnVivid),
                        const SizedBox(width: 4),
                        Text('Add', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
                      ]),
                    ),
                  ),
                ],
              ),
              if (thisMonthIncomes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No income added yet.', style: GoogleFonts.inter(color: AC.textLight, fontSize: 11)),
                )
              else
                ...thisMonthIncomes.map((income) => _buildIncomeTile(income)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeTile(Income income) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AC.success.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: const Text('💰', style: TextStyle(fontSize: 18)),
        ),
        title: Text(fmtAmount(income.amount), style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AC.text, fontSize: 15)),
        subtitle: income.note?.isNotEmpty == true
            ? Text(income.note!, style: GoogleFonts.inter(color: AC.textLight, fontSize: 12))
            : Text(DateFormat('dd MMM').format(income.createdAt), style: GoogleFonts.inter(color: AC.textLight, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _addOrEditIncome(income),
              child: Icon(Icons.edit_rounded, size: 18, color: AC.textLight),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _deleteIncome(income.key as int),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red[300]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AC.textLight, letterSpacing: 1.2)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingsTile({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AC.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(color: AC.text, fontSize: 15))),
          trailing,
        ],
      ),
    );
  }
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1: return '${n}st';
    case 2: return '${n}nd';
    case 3: return '${n}rd';
    default: return '${n}th';
  }
}

class _SalaryDatePicker extends StatefulWidget {
  final int? current;
  final ValueChanged<int> onSelected;
  final VoidCallback onCleared;

  const _SalaryDatePicker({
    required this.current,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  State<_SalaryDatePicker> createState() => _SalaryDatePickerState();
}

class _SalaryDatePickerState extends State<_SalaryDatePicker> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AC.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AC.accent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Salary Date',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AC.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick the day your salary is credited each month',
            style: GoogleFonts.inter(fontSize: 12, color: AC.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 4-column grid of day buttons 1–28
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 28,
            itemBuilder: (_, index) {
              final day = index + 1;
              final isSelected = _selected == day;
              return GestureDetector(
                onTap: () => setState(() => _selected = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? AC.accent : AC.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AC.accent : AC.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AC.bg : AC.text,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.current != null)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onCleared();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AC.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AC.accent.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Clear', style: GoogleFonts.inter(fontSize: 15, color: AC.textLight)),
                    ),
                  ),
                ),
              if (widget.current != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    if (_selected != null) {
                      Navigator.pop(context);
                      widget.onSelected(_selected!);
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AC.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _selected != null ? 'Set to ${_ordinal(_selected!)}' : 'Select a day',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selected != null ? AC.textOnVivid : AC.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

