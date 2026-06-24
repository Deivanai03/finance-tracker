import 'package:hive/hive.dart';
import '../models/recurring_expense.dart';

class RecurringExpenseService {
  static Box<RecurringExpense> get _box => Hive.box<RecurringExpense>('recurring_expenses');

  static Future<void> add({
    required String name,
    required double amount,
    required int categoryId,
    required int dayOfMonth,
  }) async {
    await _box.add(RecurringExpense(name: name, amount: amount, categoryId: categoryId, dayOfMonth: dayOfMonth));
  }

  static Future<void> delete(int key) async => await _box.delete(key);

  static Future<void> update({
    required int key,
    required String name,
    required double amount,
    required int categoryId,
    required int dayOfMonth,
  }) async {
    final r = _box.get(key);
    if (r == null) return;
    r.name = name;
    r.amount = amount;
    r.categoryId = categoryId;
    r.dayOfMonth = dayOfMonth;
    await r.save();
  }

  static List<RecurringExpense> getAll() => _box.values.toList();

  /// Returns items due today or within the next 3 days, or overdue this month (not yet paid).
  static List<RecurringExpense> getDueSoon() {
    final now = DateTime.now();
    return getAll().where((r) {
      // Already paid this month?
      if (r.lastPaidAt != null &&
          r.lastPaidAt!.year == now.year &&
          r.lastPaidAt!.month == now.month) return false;
      // Due within today..+3 days OR already past due this month
      return r.dayOfMonth <= now.day + 3;
    }).toList()
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }

  static Future<void> markPaid(int key) async {
    final r = _box.get(key);
    if (r == null) return;
    r.lastPaidAt = DateTime.now();
    await r.save();
  }
}
