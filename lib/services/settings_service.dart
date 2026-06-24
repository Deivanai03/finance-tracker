import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static Box get _box => Hive.box('settings');

  static bool get isDarkMode => _box.get('isDarkMode', defaultValue: false) as bool;
  static set isDarkMode(bool value) => _box.put('isDarkMode', value);

  static double? get monthlyBudget => _box.get('monthlyBudget') as double?;
  static set monthlyBudget(double? value) => _box.put('monthlyBudget', value);
}
