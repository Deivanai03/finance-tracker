import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  int categoryId;

  @HiveField(2)
  String? note;

  @HiveField(3)
  DateTime createdAt;

  Expense({
    required this.amount,
    required this.categoryId,
    this.note,
    required this.createdAt,
  });
}
