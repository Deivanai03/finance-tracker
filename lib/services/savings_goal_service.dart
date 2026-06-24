import 'package:hive/hive.dart';
import '../models/savings_goal.dart';

class SavingsGoalService {
  static Box<SavingsGoal> get _box => Hive.box<SavingsGoal>('savings_goals');

  static Future<void> add({required String name, required String emoji, required double targetAmount}) async {
    await _box.add(SavingsGoal(name: name, emoji: emoji, targetAmount: targetAmount, createdAt: DateTime.now()));
  }

  static List<SavingsGoal> getAll() => _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Future<void> addSavings(int key, double amount) async {
    final goal = _box.get(key);
    if (goal == null) return;
    goal.savedAmount = (goal.savedAmount + amount).clamp(0, goal.targetAmount);
    await goal.save();
  }

  static Future<void> delete(int key) async => _box.delete(key);

  static Future<void> update({required int key, required String name, required String emoji, required double targetAmount}) async {
    final goal = _box.get(key);
    if (goal == null) return;
    goal.name = name;
    goal.emoji = emoji;
    goal.targetAmount = targetAmount;
    await goal.save();
  }
}
