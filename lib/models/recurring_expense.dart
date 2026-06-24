import 'package:hive/hive.dart';

part 'recurring_expense.g.dart';

@HiveType(typeId: 2)
class RecurringExpense extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  int categoryId;

  @HiveField(3)
  int dayOfMonth; // 1–28

  @HiveField(4)
  DateTime? lastPaidAt;

  RecurringExpense({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.dayOfMonth,
    this.lastPaidAt,
  });
}
