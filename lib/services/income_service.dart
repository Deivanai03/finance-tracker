import 'package:hive/hive.dart';
import '../models/income.dart';
import 'settings_service.dart';

class IncomeService {
  static Box<Income> get _box => Hive.box<Income>('incomes');

  static Future<void> add({required double amount, String? note}) async {
    await _box.add(Income(amount: amount, note: note, createdAt: DateTime.now()));
  }

  static List<Income> getAll() {
    return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static double getCurrentMonthTotal() {
    final now = DateTime.now();
    return _box.values
        .where((i) => i.createdAt.year == now.year && i.createdAt.month == now.month)
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  /// Total income in the current salary cycle.
  static double getCurrentCycleTotal() {
    final start = SettingsService.cycleStart;
    final end = SettingsService.cycleEnd;
    return _box.values
        .where((i) => !i.createdAt.isBefore(start) && !i.createdAt.isAfter(end))
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  static Future<void> delete(int key) async {
    await _box.delete(key);
  }

  static Future<void> update({
    required int key,
    required double amount,
    String? note,
    DateTime? createdAt,
  }) async {
    final income = _box.get(key);
    if (income == null) return;
    income.amount = amount;
    income.note = note;
    if (createdAt != null) income.createdAt = createdAt;
    await income.save();
  }
}
