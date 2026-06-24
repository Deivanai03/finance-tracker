import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String emoji;

  @HiveField(2)
  double? budget;

  Category({required this.name, required this.emoji, this.budget});
}
