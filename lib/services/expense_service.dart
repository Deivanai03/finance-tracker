import 'package:hive/hive.dart';
import '../models/expense.dart';
import 'settings_service.dart';

class ExpenseService {
  static Box<Expense> get _box => Hive.box<Expense>('expenses');

  // ================= CRUD =================

  static Future<void> addExpense({
    required double amount,
    required int categoryId,
    String? note,
  }) async {
    await _box.add(Expense(
      amount: amount,
      categoryId: categoryId,
      note: note,
      createdAt: DateTime.now(),
    ));
  }

  static Future<void> updateExpense({
    required int key,
    required double amount,
    required int categoryId,
    String? note,
    DateTime? createdAt,
  }) async {
    final expense = _box.get(key);
    if (expense == null) return;
    expense.amount = amount;
    expense.categoryId = categoryId;
    expense.note = note;
    if (createdAt != null) expense.createdAt = createdAt;
    await expense.save();
  }

  static Future<void> deleteExpense(int key) async {
    await _box.delete(key);
  }

  static Future<void> reassignCategory({
    required int fromCategoryId,
    required int toCategoryId,
  }) async {
    for (final expense in _box.values) {
      if (expense.categoryId == fromCategoryId) {
        expense.categoryId = toCategoryId;
        await expense.save();
      }
    }
  }

  // ================= QUERIES =================

  static List<Expense> getAllExpenses() => _box.values.toList();

  static List<Expense> getAllExpensesSorted() {
    final list = getAllExpenses()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static List<Expense> getExpensesByCategory(int categoryId) {
    return getAllExpensesSorted()
        .where((e) => e.categoryId == categoryId)
        .toList();
  }

  static int getExpenseKey(Expense expense) => expense.key as int;

  // ================= HELPERS =================

  static double _sum(List<Expense> expenses) =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  static List<Expense> _filterByMonth(List<Expense> expenses, DateTime target) =>
      expenses
          .where((e) => e.createdAt.year == target.year && e.createdAt.month == target.month)
          .toList();

  static List<Expense> _filterByDay(List<Expense> expenses, DateTime target) =>
      expenses
          .where((e) =>
              e.createdAt.year == target.year &&
              e.createdAt.month == target.month &&
              e.createdAt.day == target.day)
          .toList();

  // ================= TOTALS =================

  static double getTotalSpent() => _sum(getAllExpenses());

  static double getCategoryTotal(int categoryId) =>
      _sum(getExpensesByCategory(categoryId));

  static double getCurrentMonthTotal() =>
      _sum(_filterByMonth(getAllExpenses(), DateTime.now()));

  static double getCurrentMonthCategoryTotal(int categoryId) =>
      _sum(_filterByMonth(getExpensesByCategory(categoryId), DateTime.now()));

  static double getTodayCategoryTotal(int categoryId) =>
      _sum(_filterByDay(getExpensesByCategory(categoryId), DateTime.now()));

  // ================= ANALYTICS =================

  static double getAverageDailySpend() {
    final expenses = getAllExpenses();
    if (expenses.isEmpty) return 0;
    final uniqueDates = expenses
        .map((e) => '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}')
        .toSet();
    return getTotalSpent() / uniqueDates.length;
  }

  static Map<int, double> getDailySpendingForCurrentMonth() {
    final now = DateTime.now();
    final Map<int, double> totals = {};
    for (final expense in getAllExpenses()) {
      final d = expense.createdAt;
      if (d.year == now.year && d.month == now.month) {
        totals[d.day] = (totals[d.day] ?? 0) + expense.amount;
      }
    }
    return totals;
  }

  static double getHighestSpendDay() {
    final Map<String, double> daily = {};
    for (final expense in getAllExpenses()) {
      final d = expense.createdAt;
      final key = '${d.year}-${d.month}-${d.day}';
      daily[key] = (daily[key] ?? 0) + expense.amount;
    }
    if (daily.isEmpty) return 0;
    return daily.values.reduce((a, b) => a > b ? a : b);
  }

  /// Returns categoryId → total map.
  static Map<int, double> getCategoryWiseTotals() {
    final Map<int, double> totals = {};
    for (final expense in getAllExpenses()) {
      totals[expense.categoryId] =
          (totals[expense.categoryId] ?? 0) + expense.amount;
    }
    return totals;
  }

  /// Returns the categoryId with the highest total spend (or -1 if empty).
  static int getTopCategoryId() {
    final totals = getCategoryWiseTotals();
    if (totals.isEmpty) return -1;
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static double getPreviousMonthTotal() {
    final prev = DateTime(DateTime.now().year, DateTime.now().month - 1);
    return _sum(_filterByMonth(getAllExpenses(), prev));
  }

  static Map<int, double> getPreviousMonthCategoryWiseTotals() {
    final prev = DateTime(DateTime.now().year, DateTime.now().month - 1);
    final Map<int, double> totals = {};
    for (final expense in _filterByMonth(getAllExpenses(), prev)) {
      totals[expense.categoryId] = (totals[expense.categoryId] ?? 0) + expense.amount;
    }
    return totals;
  }

  // ================= MONTH-PARAMETERIZED =================

  static double getMonthTotal(DateTime month) =>
      _sum(_filterByMonth(getAllExpenses(), month));

  static Map<int, double> getCategoryWiseTotalsForMonth(DateTime month) {
    final Map<int, double> totals = {};
    for (final expense in _filterByMonth(getAllExpenses(), month)) {
      totals[expense.categoryId] = (totals[expense.categoryId] ?? 0) + expense.amount;
    }
    return totals;
  }

  static Map<int, double> getDailySpendingForMonth(DateTime month) {
    final Map<int, double> totals = {};
    for (final expense in _filterByMonth(getAllExpenses(), month)) {
      final d = expense.createdAt;
      totals[d.day] = (totals[d.day] ?? 0) + expense.amount;
    }
    return totals;
  }

  static double getAverageDailySpendForMonth(DateTime month) {
    final expenses = _filterByMonth(getAllExpenses(), month);
    if (expenses.isEmpty) return 0;
    final uniqueDates = expenses.map((e) => e.createdAt.day).toSet();
    return _sum(expenses) / uniqueDates.length;
  }

  static double getHighestSpendDayForMonth(DateTime month) {
    final daily = getDailySpendingForMonth(month);
    if (daily.isEmpty) return 0;
    return daily.values.reduce((a, b) => a > b ? a : b);
  }

  static int getTopCategoryIdForMonth(DateTime month) {
    final totals = getCategoryWiseTotalsForMonth(month);
    if (totals.isEmpty) return -1;
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ================= CYCLE-AWARE TOTALS =================

  static List<Expense> _filterByCycle(List<Expense> expenses) {
    final start = SettingsService.cycleStart;
    final end = SettingsService.cycleEnd;
    return expenses.where((e) {
      return !e.createdAt.isBefore(start) && !e.createdAt.isAfter(end);
    }).toList();
  }

  /// Total spent in the current salary cycle.
  static double getCurrentCycleTotal() =>
      _sum(_filterByCycle(getAllExpenses()));

  /// Total spent in the current salary cycle for a specific category.
  static double getCurrentCycleCategoryTotal(int categoryId) =>
      _sum(_filterByCycle(getExpensesByCategory(categoryId)));
}
