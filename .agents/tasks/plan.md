# Implementation Plan — Finance Tracker Theme Redesign

## Pre-flight notes

- **Build command:** `flutter build apk --debug` (or `flutter run`)
- **Verify compilation:** `flutter analyze && flutter build apk --debug`
- No test suite exists; verification is build-clean + visual inspection.
- All files use `AC` (the global getter in `main.dart`) — any field rename in `AppColors` must be tracked across every file.
- **Current `AppColors` fields:** `bg, primary, accent, secondary, card, success, text, textLight`
- **New `AppColors` fields:** `bg, card, hero, accent, text, textLight, textOnVivid, success, primary`
  - Removed: `secondary`
  - Added: `hero, textOnVivid`
  - `primary` meaning changes: was a tint color, now is a very-slightly-off background (`#F0F0E8` / `#252540`)
- Every use of `AC.secondary` in the codebase must be replaced before it compiles.
- `withOpacity(...)` in `add_category_sheet.dart` (2 places) must be changed to `withValues(alpha: ...)` — Dart 3 deprecation that will cause a warning but not a compile error; handle in the same pass.
- The `_lightCardColors` / `_darkCardColors` local lists in `home_screen.dart` and `wishlist_screen.dart` and `analytics_screen.dart` are replaced by the single `AppColors.cardColors` static list.
- `AnimatedBubble` class and `_buildBubbleChart` in `analytics_screen.dart` are deleted and replaced with a new `_buildStackedBar` widget.
- `_buildSparkles()` method and `_sparkleController` field in `home_screen.dart` are deleted.
- `_heroController` / `_heroFade` in `home_screen.dart`: the spec says "remove sparkle animations, replace hero with static decorative circles" but also says "keep hero animations on navigation transitions". Keep `_heroController`/`_heroFade` wrapping the header (not removed), only remove `_sparkleController` and `_buildSparkles`.
- The `dart:ui` import in `main_navigation_screen.dart` (for `BackdropFilter`) will be unused after the nav bar replacement — remove it.
- `add_category_sheet.dart` uses `withOpacity` (old API) — fix those 3 occurrences to `withValues(alpha:)` in this pass.

---

## Step 1 — `lib/main.dart`: Replace AppColors

**What:** Replace the entire `AppColors` class with the new definition. Update `_buildTheme` to use `colors.bg` for scaffoldBackgroundColor and `colors.accent` as `seedColor`. Remove the `secondary` field from both `light` and `dark` const instances.

**Exact changes:**

1. Replace the class body (fields, constructor, `light`, `dark` instances) with:
   ```dart
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
       Color(0xFFFF6B6B), // coral
       Color(0xFFFFD93D), // yellow
       Color(0xFF6BCB77), // teal
       Color(0xFFC77DFF), // purple
       Color(0xFF4D96FF), // blue
       Color(0xFFFF6BD6), // pink
       Color(0xFFFF9F43), // orange
       Color(0xFFA8E063), // lime
     ];
   }
   ```

2. In `_buildTheme`, update:
   ```dart
   scaffoldBackgroundColor: colors.bg,   // was already colors.bg — verify
   colorScheme: ColorScheme.fromSeed(
     seedColor: colors.accent,           // was colors.accent — verify
     brightness: isDark ? Brightness.dark : Brightness.light,
     surface: colors.card,
   ).copyWith(
     primary: colors.accent,
     surface: colors.card,
     onSurface: colors.text,
     // REMOVE: secondary: colors.secondary,
   ),
   ```
   Remove the `secondary: colors.secondary` line from `.copyWith(...)`.

**Files:** `lib/main.dart`

**Compile risk:** The `const` constructor requires every named parameter to be listed in the exact order they appear in the constructor signature. The order above matches the field declaration order — keep them aligned. After this step, every other file that references `AC.secondary` will fail to compile; those are resolved in subsequent steps.

**Verify:** `flutter analyze` — expect errors only about `AC.secondary` usages in other files (not about `AppColors` itself).

---

## Step 2 — `lib/screens/home_screen.dart`: Complete Visual Rewrite

**What:** Rewrite visual widgets while keeping every line of business logic (sorting, reorder, confetti, salary cycle, `_heroController`/`_heroFade`). Remove `_sparkleController` and `_buildSparkles`. Replace local card color lists with `AppColors.cardColors`.

**Exact changes, section by section:**

### 2a. Imports — add `dart:math` is already present. Remove nothing.

### 2b. Remove fields and init
- Delete `_sparkleController` field declaration.
- Delete `_sparkleController = AnimationController(vsync: this, ...)..repeat(reverse: true);` from `initState`.
- Delete `_sparkleController.dispose();` from `dispose`.
- Delete `static const _lightCardColors`, `static const _darkCardColors`, and `List<Color> get _cardBgColors` getter.

### 2c. `_buildHeader` — replace widget tree only

Replace the entire method body (keep the signature `Widget _buildHeader(double totalSpent, double totalIncome, double? budget)`).

New body:
```dart
Widget _buildHeader(double totalSpent, double totalIncome, double? budget) {
  final prevMonth = ExpenseService.getPreviousMonthTotal();
  final day = DateTime.now().day;
  final hasPrevData = prevMonth > 0;

  return FadeTransition(
    opacity: _heroFade,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(_greeting(), style: GoogleFonts.inter(fontSize: 13, color: AC.textLight)),
          const SizedBox(height: 4),
          // Title row with two icon buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your month', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AC.text)),
              Row(
                children: [
                  _headerIconButton(
                    icon: Icons.delete_sweep_rounded,
                    onTap: () => Navigator.push(context, fadeScaleRoute(const WishlistScreen())),
                  ),
                  const SizedBox(width: 8),
                  _headerIconButton(
                    icon: Icons.tune_rounded,
                    onTap: () => Navigator.push(context, fadeScaleRoute(const SettingsScreen())),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeroCard(totalSpent, totalIncome, budget),
          if (day <= 3 && hasPrevData) ...[
            const SizedBox(height: 12),
            _buildMonthlySummary(prevMonth),
          ],
        ],
      ),
    ),
  );
}

Widget _headerIconButton({required IconData icon, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AC.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AC.textLight),
    ),
  );
}
```

> **Note on nav icons:** The original had a 🛍️ wishlist button and a settings gear. The spec says "delete/reset icon + filter/settings icon". Map the left button to wishlist (delete_sweep is close enough for "reset") and the right to settings (tune = filter/settings). If the user later wants to swap these icons that is a trivial one-liner change.

### 2d. `_buildHeroCard` — replace widget tree only

Replace from the `return Container(...)` down (keep the method signature and the `hasBudget`/`budgetProgress`/`overBudget`/`cycleLabel` local variable block):

```dart
Widget _buildHeroCard(double totalSpent, double totalIncome, double? budget) {
  final hasBudget = budget != null && budget > 0;
  final budgetProgress = hasBudget ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
  final overBudget = hasBudget && totalSpent > budget;

  final cycleStart = SettingsService.cycleStart;
  final cycleEnd = SettingsService.cycleEnd;
  final hasSalaryDate = SettingsService.salaryDate != null;
  final cycleLabel = hasSalaryDate
      ? '${DateFormat('dd MMM').format(cycleStart)} – ${DateFormat('dd MMM').format(cycleEnd)}'
      : 'This month';

  return Container(
    width: double.infinity,
    height: 160,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AC.hero,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        // Decorative circle — coral, top-right
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B6B),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Decorative circle — purple, center-right
        Positioned(
          top: 30,
          right: 50,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFC77DFF).withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(cycleLabel, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUpText(
                  totalSpent,
                  style: GoogleFonts.dmSans(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D)),
                ),
                if (hasBudget) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: budgetProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(
                        overBudget ? Colors.red[300]! : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    overBudget
                        ? '⚠️ Over budget'
                        : 'Budget: ${fmtAmount(totalSpent)} / ${fmtAmount(budget)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: overBudget ? Colors.red[400] : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
```

### 2e. Categories section header

In the `build` method, find the `SliverPadding` that wraps the non-reorder `SliverGrid`. Above it (still inside the `slivers` list), add:

```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Categories', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AC.text)),
        Text('bigger card = bigger spend', style: GoogleFonts.inter(fontSize: 12, color: AC.textLight)),
      ],
    ),
  ),
),
```

Also change the `SliverGrid`'s delegate: `crossAxisSpacing: 10`, `mainAxisSpacing: 10`, `childAspectRatio: 0.95` (currently 12/12/0.95 — change 12→10).

### 2f. `_buildCategoryCard` — replace widget tree only

Replace from the outermost `return GestureDetector(...)` (keep the signature and local variable block `categoryId`, `total`, `bgColor`):

```dart
Widget _buildCategoryCard(BuildContext context, Category category, int index) {
  final categoryId = category.key as int;
  final total = ExpenseService.getCurrentCycleCategoryTotal(categoryId);
  final bgColor = AppColors.cardColors[index % AppColors.cardColors.length];

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      fadeScaleRoute(CategoryDetailsScreen(categoryId: categoryId, categoryName: category.name, emoji: category.emoji)),
    ).then((_) => setState(() {})),
    onLongPress: () {
      HapticFeedback.mediumImpact();
      setState(() => _reorderMode = true);
    },
    child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        // NO box shadow
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Hero(
                tag: 'emoji_$categoryId',
                flightShuttleBuilder: (_, animation, __, fromContext, toContext) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (_, __) {
                      final size = Tween<double>(begin: 32, end: 64).evaluate(
                        CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
                      );
                      return Material(
                        type: MaterialType.transparency,
                        child: Text(category.emoji, style: TextStyle(fontSize: size, decoration: TextDecoration.none)),
                      );
                    },
                  );
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(category.emoji, style: const TextStyle(fontSize: 28, decoration: TextDecoration.none)),
                ),
              ),
              // "+" quick-add button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddExpenseSheet(categoryId: categoryId),
                  );
                  setState(() {});
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            category.name,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AC.textOnVivid),
          ),
          const SizedBox(height: 3),
          Text(
            fmtAmount(total),
            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.bold, color: AC.textOnVivid),
          ),
          if (category.budget != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (total / category.budget!).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

### 2g. `_buildAddCategoryCard` — replace container decoration only

Change:
```dart
// OLD
border: Border.all(color: AC.accent.withValues(alpha: 0.4), width: 1.5),
```
To:
```dart
// NEW
border: Border.all(
  color: themeNotifier.value ? const Color(0xFF444466) : const Color(0xFFCCCCCC),
  width: 1.5,
),
```
Also change the `Icon` to `const Icon(Icons.add, size: 28, color: AC.textLight)` (remove `_rounded` variant, keep plain `Icons.add`; the text "New Category" stays).

> Note: `AC.textLight` reference inside a `const` context in `_buildAddCategoryCard` is fine because it's not a `const Icon` (the container isn't const-constructed).

### 2h. `_buildDraggableCategoryCard` — update colors and remove shadow

Change `bgColor` assignment:
```dart
final bgColor = AppColors.cardColors[index % AppColors.cardColors.length];
```
Remove `boxShadow` from the Container's BoxDecoration. Update text colors from `AC.text` → `AC.textOnVivid` for name and amount. Progress bar colors: `AC.text.withValues(alpha: 0.15)` → `Colors.white.withValues(alpha: 0.3)`, value color → `AC.accent` (keep over-budget red).

### 2i. `_buildInsights` — update background color

Change `AC.primary.withValues(alpha: 0.5)` → `AC.card` (the pill now sits on AC.card for contrast).

### 2j. `_buildMonthlySummary` — fix `AC.secondary` reference

Change `AC.secondary.withValues(alpha: 0.5)` → `AC.card`.

### 2k. `build()` — fix ConfettiWidget colors

Change `AC.secondary` → `AC.primary` in the confetti colors list:
```dart
colors: [AC.accent, AC.success, AC.primary, const Color(0xFFFFD700)],
```

**Files:** `lib/screens/home_screen.dart`

**Verify:** `flutter analyze` — zero errors in this file. Then `flutter run` and visually confirm hero card dark bg, yellow amount, colorful category cards.

---

## Step 3 — `lib/screens/analytics_screen.dart`: Visual Overhaul

**What:** Replace `_lightTints`/`_darkTints` with `AppColors.cardColors`. Replace `_buildBubbleChart` + `AnimatedBubble` with `_buildStackedBar`. Add vivid colors to stat cards. Update month-picker pill color.

### 3a. Imports

Add no new imports — `dart:math` already imported. The `AnimatedBubble` class and `_AnimatedBubbleState` at the bottom of the file will be removed.

### 3b. Delete `_lightTints`, `_darkTints`, `_pastelTints` getter

Remove all three declarations.

### 3c. Delete `AnimatedBubble` and `_AnimatedBubbleState` classes

Remove from `class AnimatedBubble extends StatefulWidget` to the end of the file.

### 3d. `_buildBubbleChart` → `_buildStackedBar`

Delete `_buildBubbleChart` entirely. Add:

```dart
Widget _buildStackedBar(List<MapEntry<int, double>> entries, double totalSpend) {
  final top5 = entries.take(5).toList();
  final total = top5.fold(0.0, (s, e) => s + e.value);
  if (total == 0) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Full-width stacked bar
      ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 14,
          child: Row(
            children: top5.asMap().entries.map((e) {
              final fraction = e.value.value / total;
              final color = AppColors.cardColors[e.key % AppColors.cardColors.length];
              return Flexible(
                flex: (fraction * 1000).round(),
                child: Container(color: color),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Legend
      ...top5.asMap().entries.map((e) {
        final cat = CategoryService.getCategoryById(e.value.key);
        final color = AppColors.cardColors[e.key % AppColors.cardColors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat != null ? '${cat.emoji} ${cat.name}' : 'Unknown',
                  style: GoogleFonts.inter(fontSize: 13, color: AC.text),
                ),
              ),
              Text(
                fmtAmount(e.value.value),
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AC.text),
              ),
            ],
          ),
        );
      }),
    ],
  );
}
```

Add the missing `fmtAmount` import at the top: `import '../utils/format.dart';`

### 3e. `build()` — update the else branch

Currently:
```dart
Text('Spending by Category', ...),
const SizedBox(height: 16),
_buildBubbleChart(entries, maxTotal),
const SizedBox(height: 32),
Text('Daily Spending', ...),
const SizedBox(height: 16),
BarChartWidget(totals: dailyTotals),
```

Replace with:
```dart
Text('Where it went', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
const SizedBox(height: 16),
_buildStackedBar(entries, monthTotal),
const SizedBox(height: 32),
Text('Daily spend', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AC.text)),
const SizedBox(height: 16),
BarChartWidget(totals: dailyTotals),
```

### 3f. `_statCard` — vivid card colors per spec

Replace the method with a version that accepts a `Color bgColor`:
```dart
Widget _statCard(String title, double value, Color bgColor) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      // NO shadow
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        CountUpText(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E))),
      ],
    ),
  );
}
```

Update call sites in `build()`:
```dart
Row(children: [
  Expanded(child: _statCard('Total Spent',  monthTotal,  const Color(0xFFC77DFF))),
  const SizedBox(width: 12),
  Expanded(child: _statCard('Avg / Day',    avgDaily,    const Color(0xFFFFD93D))),
]),
const SizedBox(height: 12),
Row(children: [
  Expanded(child: _statCard('Highest Day',  highestDay,  const Color(0xFFFF6B6B))),
  const SizedBox(width: 12),
  Expanded(child: _topCatCard(topCategory == null ? 'None' : '${topCategory.emoji} ${topCategory.name}')),
]),
```

### 3g. `_topCatCard` — match vivid style

```dart
Widget _topCatCard(String value) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF6BCB77),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Category', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
```

### 3h. Month picker pill — update color

Find the Container that wraps the month name text. Change `color: AC.primary` → `color: const Color(0xFFC77DFF)`. Change the text color → `Colors.white`.

**Files:** `lib/screens/analytics_screen.dart`

**Verify:** `flutter analyze` — zero errors. Visual: vivid stat cards, stacked bar, no bubble chart.

---

## Step 4 — `lib/screens/main_navigation_screen.dart`: Replace Nav Bar

**What:** Remove the floating pill with `BackdropFilter`. Replace with a flat bottom bar. Active item shows accent pill with label; inactive shows just icon.

### 4a. Imports

Remove `import 'dart:ui';` (no longer needed after removing `BackdropFilter`).

### 4b. `build()` — replace `bottomNavigationBar`

Replace the entire `bottomNavigationBar: Padding(...)` widget with:

```dart
bottomNavigationBar: Container(
  height: 64,
  decoration: BoxDecoration(
    color: AC.card,
    border: Border(
      top: BorderSide(color: AC.textLight.withValues(alpha: 0.15), width: 1),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _NavItem(icon: Icons.home_rounded,         label: 'Home',      selected: _index == 0, onTap: () => setState(() => _index = 0)),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'History',   selected: _index == 1, onTap: () => setState(() => _index = 1)),
      _NavItem(icon: Icons.auto_graph_rounded,   label: 'Analytics', selected: _index == 2, onTap: () => setState(() => _index = 2)),
      _NavItem(icon: Icons.repeat_rounded,       label: 'Recurring', selected: _index == 3, onTap: () => setState(() => _index = 3)),
    ],
  ),
),
```

Also update `extendBody: false` — with a flat nav bar there is no need to extend body underneath it.

### 4c. `_NavItem` widget — replace `build`

```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AC.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? AC.textOnVivid : AC.textLight, size: 22),
          if (selected) ...[
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(color: AC.textOnVivid, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ],
      ),
    ),
  );
}
```

**Files:** `lib/screens/main_navigation_screen.dart`

**Verify:** `flutter analyze` — zero errors. Visual: flat nav bar with yellow pill on active item.

---

## Step 5 — `lib/screens/history_screen.dart`: Style Updates

**What:** Style-only pass — zero logic changes. Fix `AC.secondary` → `AC.primary` or `AC.card`.

### 5a. Search bar: `fillColor` already `AC.card` — no change needed.

### 5b. Total bar container: change `color: AC.primary` → `AC.card`, add left accent border:
```dart
decoration: BoxDecoration(
  color: AC.card,
  borderRadius: BorderRadius.circular(12),
  border: Border(
    left: BorderSide(color: AC.accent, width: 4),
  ),
),
```

### 5c. Expense tile leading icon container: change `color: AC.primary` → `AppColors.cardColors[expense.categoryId % 8]` as background. Change emoji text color to `AC.textOnVivid`.

```dart
leading: Container(
  width: 44, height: 44,
  decoration: BoxDecoration(
    color: AppColors.cardColors[expense.categoryId % 8],
    borderRadius: BorderRadius.circular(12),
  ),
  alignment: Alignment.center,
  child: Text(category?.emoji ?? '💰', style: const TextStyle(fontSize: 22)),
),
```

### 5d. Date group header: accent dot stays `AC.accent` — already correct. No change needed.

### 5e. Sort button background: change `AC.primary` → `AC.card`.

### 5f. Tile box shadow: change `AC.primary.withValues(alpha: 0.2)` → `Colors.black.withValues(alpha: 0.04)` for a subtler shadow.

**Files:** `lib/screens/history_screen.dart`

**Verify:** `flutter analyze` — zero errors. Visual: colorful category icons in history tiles.

---

## Step 6 — `lib/screens/settings_screen.dart`: Style Updates

**What:** Style-only pass — zero logic changes. Fix `AC.secondary` → appropriate new colors. Fix "Add income" button gradient.

### 6a. `_SectionLabel` — update `letterSpacing`:

Change the `_SectionLabel` widget's text style to:
```dart
GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AC.textLight, letterSpacing: 1.2)
```
(currently `fontSize: 12`, `letterSpacing: 1` — adjust both)

### 6b. All tile icons already use `AC.accent` — no change needed.

### 6c. "Add income" gradient button: change gradient from `[AC.accent, AC.primary]` → solid `AC.accent`, text color `AC.textOnVivid`:
```dart
decoration: BoxDecoration(
  color: AC.accent,   // was LinearGradient
  borderRadius: BorderRadius.circular(10),
),
child: Row(children: [
  Icon(Icons.add, size: 14, color: AC.textOnVivid),
  const SizedBox(width: 4),
  Text('Add', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AC.textOnVivid)),
]),
```

### 6d. `_SalaryDatePicker` — fix gradient button (uses `[AC.accent, AC.primary]`):

Change:
```dart
gradient: LinearGradient(colors: [AC.accent, AC.primary], begin: ..., end: ...),
```
To:
```dart
color: AC.accent,
```
And text color from `AC.bg` → `AC.textOnVivid`.

### 6e. Income tile `_buildIncomeTile` — leading container: `AC.success.withValues(alpha: 0.4)` stays as-is (teal tint is fine for income).

**Files:** `lib/screens/settings_screen.dart`

**Verify:** `flutter analyze` — zero errors.

---

## Step 7 — `lib/screens/wishlist_screen.dart`: Card Color Update

**What:** Replace local light/dark card color lists with `AppColors.cardColors`. Fix `AC.secondary` usage.

### 7a. Delete `_lightCardColors`, `_darkCardColors` static fields, and `_cardColors` getter.

### 7b. In `_buildGoalCard`, change:
```dart
// OLD
final color = isComplete ? AC.success : _cardColors[index % _cardColors.length];
// NEW
final color = isComplete ? AC.success : AppColors.cardColors[index % AppColors.cardColors.length];
```

### 7c. Fix `_showAddSavings` gradient button: change `LinearGradient(colors: [AC.accent, AC.primary], ...)` → `color: AC.accent`. Text/icon color `AC.text` → `AC.textOnVivid`.

### 7d. "Add" button in header row: change `LinearGradient(colors: [AC.accent, AC.primary])` → `color: AC.accent`. Text/icon `AC.text` → `AC.textOnVivid`.

### 7e. Remove `boxShadow` from goal cards (for consistency with the spec "no box shadow" style). Keep the `ClipRRect` progress bar and the `+ Add savings` button as-is.

### 7f. ConfettiWidget colors: `AC.secondary` → `AC.primary`.

**Files:** `lib/screens/wishlist_screen.dart`

**Verify:** `flutter analyze` — zero errors.

---

## Step 8 — Bottom Sheet Widgets: Style Updates

**What:** Update all 6 sheets to use `AC.accent` solid button background + `AC.textOnVivid` text. Fix `withOpacity` → `withValues(alpha:)` in `add_category_sheet.dart`. These sheets currently use `LinearGradient(colors: [AC.accent, AC.primary])` for buttons — change to solid `color: AC.accent` with text `AC.textOnVivid`.

### 8a. `lib/widgets/add_expense_sheet.dart`

- Save button: replace `LinearGradient(colors: [AC.accent, AC.primary], ...)` + `boxShadow` with:
  ```dart
  color: AC.accent,
  borderRadius: BorderRadius.circular(16),
  ```
  Change text `color: AC.text` → `AC.textOnVivid`. Remove `boxShadow`.
- Amount container background: `AC.primary.withValues(alpha: 0.4)` → `AC.card` (slightly more neutral).
- No other changes.

### 8b. `lib/widgets/add_category_sheet.dart`

- Fix `withOpacity` calls (lines in `_border()`, Container decorations): change all `.withOpacity(...)` → `.withValues(alpha: ...)`. There are 3 occurrences:
  - `AC.accent.withOpacity(0.3)` in `_border()` → `AC.accent.withValues(alpha: 0.3)`
  - `AC.accent.withOpacity(0.4)` in the drag handle container → `AC.accent.withValues(alpha: 0.4)`
  - `AC.accent.withOpacity(0.4)` in the save button `BoxShadow` → remove entirely (shadow is dropped when converting to solid button)
- Save button: same as 8a — replace gradient with `color: AC.accent`, text `AC.textOnVivid`.
- Input `style: GoogleFonts.inter(fontSize: 24, color: Colors.black)` → `color: AC.text` (respect theme).

### 8c. `lib/widgets/edit_category_sheet.dart`

- Save button: gradient → `color: AC.accent`, text `AC.textOnVivid`.
- Input text styles `color: Colors.black` → `AC.text`.

### 8d. `lib/widgets/add_goal_sheet.dart`

- Save button: gradient → `color: AC.accent`, text `AC.textOnVivid`.
- Input text styles `color: Colors.black` → `AC.text`.

### 8e. `lib/widgets/add_income_sheet.dart`

- Save button: gradient → `color: AC.accent`, text `AC.textOnVivid`.
- Amount container background: `AC.success.withValues(alpha: 0.3)` — keep (income distinction).

### 8f. `lib/widgets/add_recurring_sheet.dart`

- Save button: gradient → `color: AC.accent`, text `AC.textOnVivid`.
- Input text styles `color: Colors.black` → `AC.text`.

**Files:** `lib/widgets/add_expense_sheet.dart`, `lib/widgets/add_category_sheet.dart`, `lib/widgets/edit_category_sheet.dart`, `lib/widgets/add_goal_sheet.dart`, `lib/widgets/add_income_sheet.dart`, `lib/widgets/add_recurring_sheet.dart`

**Verify:** `flutter analyze` — zero errors across all widget files.

---

## Step 9 — `lib/widgets/bar_chart_widget.dart`: Update Bar Colors

**What:** The bar chart currently uses a gradient `[AC.accent, AC.primary]`. Update to use `AC.accent` solid color for the bars, keeping `AC.card` container. Also remove `boxShadow`.

- Bar rod gradient → `color: AC.accent` (remove `gradient:` field, use `color:` field on `BarChartRodData`).
- Container `boxShadow` → remove.

**Files:** `lib/widgets/bar_chart_widget.dart`

**Verify:** `flutter analyze` — zero errors.

---

## Step 10 — Final Full Build Verification

**What:** Run the full analyzer and build to confirm zero compile errors across all modified files.

**Command:**
```
flutter analyze
flutter build apk --debug
```

**Expected outcome:** Zero errors, zero `AC.secondary` references remaining, zero `withOpacity` calls remaining, APK builds successfully.

**Files:** None changed in this step — it is purely a verification gate.

---

## Step 11 — `category_details_screen.dart` and `manage_recurring_screen.dart`: Fix `AC.secondary`

**What:** These two files were not in the original spec scope but reference `AC.secondary` which will no longer compile after Step 1. Style-only fixes — zero logic changes.

### 11a. `lib/screens/category_details_screen.dart`

**`AC.secondary` occurrences (found at lines ~185, ~223, ~310):**

1. **`FlexibleSpaceBar` gradient** (line ~185):
   ```dart
   // OLD
   gradient: LinearGradient(colors: [AC.primary, AC.secondary], ...)
   // NEW — use AC.hero for the dark app-bar feel
   gradient: LinearGradient(colors: [AC.primary, AC.hero], ...)
   ```

2. **`_statCard('Today', ..., AC.secondary)` call** (line ~223):
   ```dart
   // OLD
   Expanded(child: _statCard('Today', fmtAmount(todayTotal), AC.secondary)),
   // NEW
   Expanded(child: _statCard('Today', fmtAmount(todayTotal), AC.card)),
   ```

3. **`_pastelTints` / `_lightTints` / `_darkTints`** (lines ~127–135, ~310): The tints are used for expense tiles within this screen. Replace the getter and static lists:
   ```dart
   // Delete _lightTints, _darkTints, _pastelTints getter.
   // In the call site: replace _pastelTints[rng.nextInt(_pastelTints.length)]
   // with: AppColors.cardColors[rng.nextInt(AppColors.cardColors.length)]
   ```
   No import change needed — `AppColors` is already accessible via `../main.dart`.

4. **`SliverAppBar` backgroundColor**: `AC.primary` stays as-is (now maps to off-white / dark bg).

### 11b. `lib/screens/manage_recurring_screen.dart`

**`AC.secondary` occurrence (line ~142):**
```dart
// OLD
color: isOverdue ? const Color(0xFFFFE4E4) : AC.secondary.withValues(alpha: 0.45),
// NEW
color: isOverdue ? const Color(0xFFFFE4E4) : AC.card,
```

**Files:** `lib/screens/category_details_screen.dart`, `lib/screens/manage_recurring_screen.dart`

**Verify:** `flutter analyze` — confirm zero `AC.secondary` references anywhere.

---

## Migration reference: AC field usage across files

| File | `AC.secondary` usages | `AC.primary` (meaning change) | Other |
|------|----------------------|-------------------------------|-------|
| `home_screen.dart` | `_buildMonthlySummary`, confetti | hero card gradient → remove | `_cardBgColors` getter removed |
| `analytics_screen.dart` | none | stat cards, month pill | bubble chart → stacked bar |
| `main_navigation_screen.dart` | none | nav pill bg was `AC.primary` | now `AC.card` |
| `history_screen.dart` | none | sort button, total bar | tile leading icon vivid |
| `settings_screen.dart` | none | none | button gradient → solid |
| `wishlist_screen.dart` | confetti colors | goal card gradient | local lists removed |
| `add_expense_sheet.dart` | none | amount container bg | button gradient → solid |
| `add_category_sheet.dart` | none | none | `withOpacity` → `withValues` |
| `add_recurring_sheet.dart` | none | none | button gradient → solid |
| `add_goal_sheet.dart` | none | none | button gradient → solid |
| `add_income_sheet.dart` | none | none | button gradient → solid |
| `edit_category_sheet.dart` | none | none | button gradient → solid |
| `category_details_screen.dart` | gradient + stat card | `_pastelTints` removed | `AC.secondary` → `AC.hero`/`AC.card` |
| `manage_recurring_screen.dart` | tile bg color | — | `AC.secondary` → `AC.card` |

## Compile-time risks checklist

1. **`const` constructor field order** — `AppColors._({...})` parameters must match field declaration order. The plan keeps them consistent.
2. **`withValues` vs `withOpacity`** — Use `withValues(alpha: x)` throughout. `withOpacity` only exists in `add_category_sheet.dart` currently; fix in Step 8b.
3. **`AC.secondary` dangling references** — All uses are in `home_screen.dart` (2) and `wishlist_screen.dart` (1). Both resolved in Steps 2 and 7. Verify with `grep -r "AC\.secondary" lib/` after Steps 2, 7 are done.
4. **`_pastelTints` / `_cardBgColors` getters** — Deleted in Steps 2 and 3; ensure no callsites remain.
5. **`_buildBubbleChart` / `AnimatedBubble`** — Deleted in Step 3; `_buildBubbleChart` is called once in the `else` branch — replaced in Step 3e.
6. **`_buildSparkles`** — Deleted in Step 2; called once inside `AnimatedBuilder` in old `_buildHeroCard` — that whole method is replaced in Step 2d.
7. **`dart:ui` import** — Removed in Step 4; verify no other `dart:ui` API is used in `main_navigation_screen.dart` after the change.
8. **`BarChartRodData.gradient` vs `color`** — `fl_chart ^1.2.0` uses `color` as a direct field (not `gradient`). Confirm the field name by checking the installed package version.
