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
        title: Text('Delete income?', style: GoogleFonts.outfit(color: AC.text, fontWeight: FontWeight.bold)),
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
                        gradient: LinearGradient(colors: [AC.accent, AC.primary]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(Icons.add, size: 14, color: AC.text),
                        const SizedBox(width: 4),
                        Text('Add', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.text)),
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
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.textLight, letterSpacing: 1)),
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
