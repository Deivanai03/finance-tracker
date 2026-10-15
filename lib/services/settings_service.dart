import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static Box get _box => Hive.box('settings');

  static bool get isDarkMode => _box.get('isDarkMode', defaultValue: false) as bool;
  static set isDarkMode(bool value) => _box.put('isDarkMode', value);

  static double? get monthlyBudget => _box.get('monthlyBudget') as double?;
  static set monthlyBudget(double? value) => _box.put('monthlyBudget', value);

  // Salary date (day-of-month, 1–28). Null = use calendar month.
  static int? get salaryDate => _box.get('salaryDate') as int?;
  static set salaryDate(int? value) => _box.put('salaryDate', value);

  // The start of the current spending cycle.
  static DateTime get cycleStart {
    final day = salaryDate;
    if (day == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, 1);
    }
    final now = DateTime.now();
    // If today >= salary day, cycle started this month on salary day
    if (now.day >= day) {
      return DateTime(now.year, now.month, day);
    } else {
      // Cycle started last month on salary day
      final prev = DateTime(now.year, now.month - 1);
      return DateTime(prev.year, prev.month, day);
    }
  }

  // The end of the current spending cycle (day before next salary).
  static DateTime get cycleEnd {
    final start = cycleStart;
    final day = salaryDate;
    if (day == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    }
    // Next cycle start
    final nextCycleStart = DateTime(start.year, start.month + 1, day);
    return nextCycleStart.subtract(const Duration(seconds: 1));
  }

  // Custom category order (list of category keys as ints). Null = default sort.
  static List<int>? get categoryOrder {
    final raw = _box.get('categoryOrder');
    if (raw == null) return null;
    try {
      final list = (jsonDecode(raw as String) as List).cast<int>();
      return list;
    } catch (_) {
      return null;
    }
  }

  static set categoryOrder(List<int>? value) {
    if (value == null) {
      _box.delete('categoryOrder');
    } else {
      _box.put('categoryOrder', jsonEncode(value));
    }
  }
}
