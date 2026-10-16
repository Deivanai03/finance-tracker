import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/category.dart';
import 'models/expense.dart';
import 'models/income.dart';
import 'models/recurring_expense.dart';
import 'models/savings_goal.dart';
import 'screens/main_navigation_screen.dart';
import 'services/category_service.dart';
import 'services/settings_service.dart';

final themeNotifier = ValueNotifier<bool>(false); // false = light

AppColors get AC => themeNotifier.value ? AppColors.dark : AppColors.light;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecurringExpenseAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  Hive.registerAdapter(IncomeAdapter());

  try {
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Category>('categories');
    await Hive.openBox<RecurringExpense>('recurring_expenses');
    await Hive.openBox<SavingsGoal>('savings_goals');
    await Hive.openBox<Income>('incomes');
    await Hive.openBox('settings');
    Hive.box<Expense>('expenses').values.toList();
    Hive.box<Category>('categories').values.toList();
  } catch (_) {
    await Hive.deleteBoxFromDisk('expenses');
    await Hive.deleteBoxFromDisk('categories');
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Category>('categories');
    await Hive.openBox<RecurringExpense>('recurring_expenses');
    await Hive.openBox<SavingsGoal>('savings_goals');
    await Hive.openBox<Income>('incomes');
    await Hive.openBox('settings');
  }

  await CategoryService.seedDefaultCategories();
  themeNotifier.value = SettingsService.isDarkMode;
  runApp(const FinanceTrackerApp());
}

class AppColors {
  final Color bg, card, hero, accent, text, textLight, textOnVivid, success, primary;

  const AppColors._({
    required this.bg,
    required this.card,
    required this.hero,
    required this.accent,
    required this.text,
    required this.textLight,
    required this.textOnVivid,
    required this.success,
    required this.primary,
  });

  static const light = AppColors._(
    bg: Color(0xFFFAFAF5),
    card: Color(0xFFFFFFFF),
    hero: Color(0xFF1A1A2E),
    accent: Color(0xFFFFD93D),
    text: Color(0xFF1A1A2E),
    textLight: Color(0xFF6B7280),
    textOnVivid: Color(0xFF1A1A2E),
    success: Color(0xFF6BCB77),
    primary: Color(0xFFF0F0E8),
  );

  static const dark = AppColors._(
    bg: Color(0xFF1A1A2E),
    card: Color(0xFF252540),
    hero: Color(0xFF252540),
    accent: Color(0xFFFFD93D),
    text: Color(0xFFFFFFFF),
    textLight: Color(0xFF9CA3AF),
    textOnVivid: Color(0xFF1A1A2E),
    success: Color(0xFF6BCB77),
    primary: Color(0xFF252540),
  );

  static const cardColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFFC77DFF),
    Color(0xFF4D96FF),
    Color(0xFFFF6BD6),
    Color(0xFFFF9F43),
    Color(0xFFA8E063),
  ];
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Finance Tracker',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(AppColors.light),
          darkTheme: _buildTheme(AppColors.dark),
          home: const MainNavigationScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(AppColors colors) {
    final isDark = colors == AppColors.dark;
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: colors.card,
      ).copyWith(
        primary: colors.accent,
        surface: colors.card,
        onSurface: colors.text,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(color: colors.text, fontWeight: FontWeight.bold).copyWith(fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji']),
        displayMedium: GoogleFonts.outfit(color: colors.text, fontWeight: FontWeight.bold).copyWith(fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji']),
        headlineLarge: GoogleFonts.outfit(color: colors.text, fontWeight: FontWeight.bold).copyWith(fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji']),
        headlineMedium: GoogleFonts.outfit(color: colors.text, fontWeight: FontWeight.w600).copyWith(fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji']),
        bodyLarge: GoogleFonts.inter(color: colors.text).copyWith(fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji']),
        bodyMedium: GoogleFonts.inter(color: colors.text).copyWith(fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji']),
      ),
      useMaterial3: true,
    );
  }
}
