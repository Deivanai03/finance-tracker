import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/savings_goal.dart';
import '../services/savings_goal_service.dart';
import '../utils/format.dart';
import '../widgets/add_goal_sheet.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _showAddSavings(SavingsGoal goal) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.accent.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Add Savings', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AC.text)),
            const SizedBox(height: 8),
            Text('for ${goal.emoji} ${goal.name}', style: GoogleFonts.inter(color: AC.textLight, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.bold, color: AC.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.bold, color: AC.accent),
                hintText: '0',
                hintStyle: GoogleFonts.dmSans(fontSize: 32, color: AC.accent.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final amount = double.tryParse(ctrl.text.trim());
                if (amount == null || amount <= 0) return;
                final wasComplete = goal.savedAmount >= goal.targetAmount;
                await SavingsGoalService.addSavings(goal.key as int, amount);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
                final updated = SavingsGoalService.getAll().firstWhere((g) => g.key == goal.key, orElse: () => goal);
                if (!wasComplete && updated.savedAmount >= updated.targetAmount) {
                  _confettiCtrl.play();
                }
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: AC.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text('Save ✨', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AC.textOnVivid)),              ),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final goals = SavingsGoalService.getAll();

    return Scaffold(
      backgroundColor: AC.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wishlist', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AC.text)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () async {
                            await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddGoalSheet());
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AC.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.add, size: 16, color: AC.textOnVivid),
                              const SizedBox(width: 4),
                              Text('Add', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (goals.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🛍️', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text('Your wishlist is empty', style: GoogleFonts.inter(fontSize: 18, color: AC.text)),
                        const SizedBox(height: 8),
                        Text('Add something you\'re saving for', style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
                      ]),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildGoalCard(goals[index], index),
                        childCount: goals.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: [AC.accent, AC.primary, AC.success, const Color(0xFFC9D8C5)],
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal, int index) {
    final progress = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    final isComplete = progress >= 1.0;
    final color = isComplete ? AC.success : AppColors.cardColors[index % AppColors.cardColors.length];
    final remaining = goal.targetAmount - goal.savedAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AC.textOnVivid)),
                    Text(
                      isComplete ? '🎉 Goal reached!' : '${fmtAmount(remaining)} to go',
                      style: GoogleFonts.inter(fontSize: 12, color: isComplete ? AC.textOnVivid : AC.textOnVivid),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddGoalSheet(existing: goal));
                  setState(() {});
                },
                child: Icon(Icons.edit_rounded, size: 18, color: AC.textLight),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AC.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Delete "${goal.name}"?', style: GoogleFonts.inter(color: AC.text, fontWeight: FontWeight.bold)),
                      content: Text('This goal and its saved amount will be removed.', style: GoogleFonts.inter(color: AC.textLight)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: AC.textLight)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: GoogleFonts.inter(color: Colors.red[400], fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ) ?? false;
                  if (confirmed) {
                    await SavingsGoalService.delete(goal.key as int);
                    setState(() {});
                  }
                },
                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red[300]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(isComplete ? const Color(0xFF6BAF8D) : AC.accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fmtAmount(goal.savedAmount)} / ${fmtAmount(goal.targetAmount)}',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: AC.textOnVivid),
              ),
              if (!isComplete)
                GestureDetector(
                  onTap: () => _showAddSavings(goal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                    child: Text('+ Add savings', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
