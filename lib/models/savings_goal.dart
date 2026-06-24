import 'package:hive/hive.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 3)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String emoji;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double savedAmount;

  @HiveField(4)
  DateTime createdAt;

  SavingsGoal({
    required this.name,
    required this.emoji,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.createdAt,
  });
}
