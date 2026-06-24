import 'package:hive/hive.dart';
import '../models/category.dart';

class CategoryService {
  static Box<Category> get _box => Hive.box<Category>('categories');

  static Future<void> addCategory({
    required String name,
    required String emoji,
  }) async {
    await _box.add(Category(name: name, emoji: emoji));
  }

  static List<Category> getAllCategories() => _box.values.toList();

  static Category? getCategoryById(int key) => _box.get(key);

  static Future<void> updateCategory({
    required int id,
    required String name,
    required String emoji,
    double? budget,
  }) async {
    final category = _box.get(id);
    if (category == null) return;
    category.name = name;
    category.emoji = emoji;
    category.budget = budget;
    await category.save();
  }

  static Future<void> deleteCategory(int id) async {
    await _box.delete(id);
  }

  static Future<void> seedDefaultCategories() async {
    if (_box.isNotEmpty) return;
    for (final entry in [
      ('Food', '🍔'),
      ('Groceries', '🛒'),
      ('Beauty', '💄'),
      ('Clothes', '👗'),
      ('Entertainment', '🎬'),
      ('Utilities', '⚡'),
      ('Rent', '🏠'),
    ]) {
      await addCategory(name: entry.$1, emoji: entry.$2);
    }
  }
}
