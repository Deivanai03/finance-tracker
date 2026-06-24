import 'package:hive/hive.dart';
part 'income.g.dart';

@HiveType(typeId: 4)
class Income extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String? note;

  @HiveField(2)
  DateTime createdAt;

  Income({required this.amount, this.note, required this.createdAt});
}
