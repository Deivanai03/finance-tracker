# Implementation Plan — Mochi Cat Theme Redesign

## Design decisions

- **Light mode only.** The `themeNotifier` / `AppColors.dark` plumbing stays intact so the dark-mode toggle in Settings keeps working, but the new palette only touches `AppColors.light`. No dark variants are redesigned.
- **Fonts.** `GoogleFonts.spaceGrotesk` replaces both `outfit` (headings/display) and `inter` (body/labels). `GoogleFonts.spaceMono` replaces `dmSans` (numbers/amounts). Both fonts are already shipped in the installed `google_fonts 6.3.3` package — no pubspec change needed.
- **MochiMood enum.** Three moods: `happy`, `sleepy`, `curious`. The widget renders a pure-Flutter custom-painted cat face so there is no image asset to manage.
- **Neon pastel palette for category/analytics cards.** Six named colours replace the existing `_lightCardColors` / `_lightTints` arrays in `home_screen.dart`, `analytics_screen.dart`, `wishlist_screen.dart`, and `category_details_screen.dart`. The dark counterparts are left as-is.
- **Hero card gradient.** Uses two new fixed `AppColors.light` fields (`heroStart`, `heroEnd`) plus an optional ghost Mochi illustration rendered as a `CustomPaint` sitting in a `Stack` on the right side of the card.
- **Insight banner.** The existing translucent `💡` pill at the top of the home screen is replaced with a rounded card that displays a Mochi face on the left (mood: `curious`) and the insight text on the right.
- **Nav bar.** The currently-selected item shows a filled pill with `AC.accent`; the icon color flips to `AC.bg` when selected so it contrasts against the pill.
- **Empty states.** Two `🌸` emoji empty states (`history_screen.dart` and `analytics_screen.dart`) are replaced with `MochiWidget(mood: MochiMood.sleepy)`. The `category_details_screen.dart` `✨` empty state is also replaced.

---

## Step-by-step plan

- [ ] 1. **Update `AppColors.light` in `lib/main.dart`**

  Replace the existing 8-field light palette with a 10-field palette that adds `heroStart` and `heroEnd`, and shifts all the base colours to the new Mochi palette:

  ```
  bg:         Color(0xFFFFF8F5)   // warm cream
  primary:    Color(0xFFFFE4EC)   // soft sakura pink
  accent:     Color(0xFFFF6B9D)   // vivid rose (Mochi's nose hue)
  secondary:  Color(0xFFE8D5FF)   // lavender
  card:       Color(0xFFFFFAF8)   // off-white card
  success:    Color(0xFFA8E6CF)   // minty green
  text:       Color(0xFF3D2B3D)   // deep plum
  textLight:  Color(0xFFB89DB8)   // muted mauve
  heroStart:  Color(0xFFFFB3CB)   // gradient start (light rose)
  heroEnd:    Color(0xFFD4A8FF)   // gradient end (soft violet)
  ```

  Add the two new fields (`heroStart`, `heroEnd`) to the `AppColors` class constructor, `light` constant, and `dark` constant (dark reuses `primary` values so it stays visually unchanged).

  Also update `_buildTheme` in `FinanceTrackerApp`: swap `GoogleFonts.interTextTheme()` → `GoogleFonts.spaceGroteskTextTheme()`, and swap all `GoogleFonts.outfit(...)` / `GoogleFonts.inter(...)` calls inside the `textTheme:` block to `GoogleFonts.spaceGrotesk(...)`.

  Files: `lib/main.dart`

  Verify: `flutter analyze lib/main.dart` — no new errors.

---

- [ ] 2. **Create `lib/widgets/mochi_widget.dart`**

  Define:
  - `enum MochiMood { happy, sleepy, curious }`
  - `class MochiWidget extends StatelessWidget` — accepts `mood`, `size` (default 80.0), and optional `label`.
  - Internally renders a `CustomPaint` using `_MochiPainter` which draws:
    - Round face circle (fill: `Color(0xFFFFF0F4)`, stroke: `Color(0xFFFFB3CB)` 2 px)
    - Two round ears (small circles top-left / top-right, same fill + stroke)
    - Eyes: for `happy` → curved line arcs (closed-eye smiling); for `sleepy` → half-moon arcs; for `curious` → open circles with a small pupil dot
    - Nose: tiny pink triangle `Color(0xFFFF6B9D)`
    - Whiskers: three lines each side, `Color(0xFFB89DB8)` 1 px
    - Blush: two semi-transparent pink ovals on cheeks `Color(0xFFFFB3CB).withValues(alpha: 0.5)`
  - If `label` is non-null, wrap `CustomPaint` + `Text` in a `Column`.

  Files: `lib/widgets/mochi_widget.dart` *(new file)*

  Verify: `flutter analyze lib/widgets/mochi_widget.dart` — no errors.

---

- [ ] 3. **Typography sweep — replace all `GoogleFonts.outfit` / `GoogleFonts.inter` / `GoogleFonts.dmSans` calls**

  The rule is:
  - `GoogleFonts.outfit(...)` → `GoogleFonts.spaceGrotesk(...)`
  - `GoogleFonts.inter(...)` → `GoogleFonts.spaceGrotesk(...)`
  - `GoogleFonts.dmSans(...)` → `GoogleFonts.spaceMono(...)`

  Apply to every file that currently imports `google_fonts`:
  - `lib/screens/home_screen.dart`
  - `lib/screens/analytics_screen.dart`
  - `lib/screens/history_screen.dart`
  - `lib/screens/settings_screen.dart`
  - `lib/screens/wishlist_screen.dart`
  - `lib/screens/category_details_screen.dart`
  - `lib/widgets/add_expense_sheet.dart`
  - `lib/widgets/add_category_sheet.dart`
  - `lib/widgets/add_goal_sheet.dart`
  - `lib/widgets/add_income_sheet.dart`
  - `lib/widgets/add_recurring_sheet.dart`
  - `lib/widgets/bar_chart_widget.dart`
  - `lib/widgets/edit_category_sheet.dart`
  - `lib/widgets/move_expenses_sheet.dart`

  ⚠️ **Potential analysis error to watch for:** `count_up_text.dart` already has an *unused* import of `google_fonts` (flagged by `flutter analyze`). Do not add font calls there; just leave the import or remove it — it does not use fonts directly.

  ⚠️ `spaceMono` is a monospace font. Existing `dmSans` calls are all on numeric/currency strings so this is intentional and correct. For readability, keep `fontWeight: FontWeight.bold` wherever the original had it — SpaceMono ships a Bold variant.

  Files: all 14 files listed above

  Verify: `flutter analyze lib/` — count of issues should not increase versus the pre-change baseline (19 infos/warnings). Compile check: `flutter build apk --debug 2>&1 | tail -20`.

---

- [ ] 4. **Update neon pastel card palette in `home_screen.dart` and all four files that share `_lightCardColors` / `_lightTints`**

  Replace the existing `_lightCardColors` / `_lightTints` arrays with this shared 6-colour neon-pastel set:

  ```dart
  static const _neonPastelColors = [
    Color(0xFFFFD6E8),  // bubblegum pink
    Color(0xFFD6E8FF),  // sky blue
    Color(0xFFD6FFE8),  // mint
    Color(0xFFFFF0D6),  // peach
    Color(0xFFE8D6FF),  // lilac
    Color(0xFFD6FFF0),  // aqua
  ];
  ```

  In each file, rename the light list to `_neonPastelColors` and keep the `_darkCardColors` array unchanged. Update the getter (`_cardColors` / `_pastelTints`) to return `_neonPastelColors` when light mode.

  Files:
  - `lib/screens/home_screen.dart` (`_lightCardColors` → `_neonPastelColors`)
  - `lib/screens/analytics_screen.dart` (`_lightTints` → `_neonPastelColors`)
  - `lib/screens/wishlist_screen.dart` (`_lightCardColors` → `_neonPastelColors`)
  - `lib/screens/category_details_screen.dart` (`_lightTints` → `_neonPastelColors`)

  Verify: `flutter analyze lib/` — no new errors.

---

- [ ] 5. **Restyle the hero card gradient and add Mochi ghost in `home_screen.dart`**

  In `_buildHeroCard`:
  - Change the `LinearGradient` colors to use `AC.heroStart` and `AC.heroEnd` (the two new fields added in step 1). The animated lerp with `_sparkleController` is preserved but targets the new hue range.
  - Inside the `Stack`, add a `Positioned` widget pinned to the right edge (`right: -8, bottom: -8`) that renders `MochiWidget(mood: MochiMood.happy, size: 90)` at 40% opacity (wrap in `Opacity(opacity: 0.4, child: ...)`). This is the "ghost" Mochi silhouette.
  - Import `'../widgets/mochi_widget.dart'` at the top of the file.

  ⚠️ The `Stack` children in `_buildHeroCard` are currently `[..._buildSparkles(), Column(...)]`. Append the new `Positioned` as the last child so it renders on top of sparkles but under no overlay.

  Files: `lib/screens/home_screen.dart`

  Verify: `flutter analyze lib/screens/home_screen.dart` — no errors. Hot-reload and visually confirm the gradient and ghost Mochi appear on the hero card.

---

- [ ] 6. **Replace the insight banner with a Mochi insight card in `home_screen.dart`**

  In `_buildInsights`, replace the current translucent pill container with:

  ```dart
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AC.primary,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AC.accent.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        MochiWidget(mood: MochiMood.curious, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Text(insightText, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AC.text)),
        ),
      ],
    ),
  )
  ```

  Keep the existing logic that computes `insightText` — only the container widget changes.

  Files: `lib/screens/home_screen.dart`

  Verify: `flutter analyze lib/screens/home_screen.dart` — no errors. Visually confirm the cat face replaces the lightbulb on the insight pill.

---

- [ ] 7. **Restyle the nav bar in `main_navigation_screen.dart`**

  In `_NavItem.build`:
  - Selected item: fill the animated pill with `AC.accent` (fully opaque, not 0.35 alpha). Set the icon color to `AC.bg` when selected so it reads against the vivid rose pill. Keep text color as `AC.text` (deep plum) — it has enough contrast on the lighter `AC.bg` background behind the bar.
  - Unselected icon color stays `AC.textLight`.
  - The pill container background: change `AC.primary` (alpha 0.85) on the bar itself to `AC.card` (alpha 0.92) for a crisper frosted look that works with the new warm cream background.
  - Border: change `Colors.white.withValues(alpha: 0.5)` to `AC.accent.withValues(alpha: 0.2)` for a subtle pink halo.
  - Box shadow: change to `AC.accent.withValues(alpha: 0.2)` blur 20 to keep the glow lighter.

  Files: `lib/screens/main_navigation_screen.dart`

  Verify: `flutter analyze lib/screens/main_navigation_screen.dart` — no errors. Visually confirm selected tab has solid rose pill with white icon.

---

- [ ] 8. **Replace `🌸` empty states with `MochiWidget(mood: MochiMood.sleepy)` in three screens**

  Three locations contain the `🌸` + label empty state pattern:

  **`lib/screens/history_screen.dart`** (line ~166):
  ```dart
  // Before
  const Text('🌸', style: TextStyle(fontSize: 48)),
  const SizedBox(height: 12),
  Text('Nothing here yet', ...)

  // After
  MochiWidget(mood: MochiMood.sleepy, size: 80),
  const SizedBox(height: 12),
  Text('Nothing here yet', style: GoogleFonts.spaceGrotesk(color: AC.textLight, fontSize: 16)),
  ```

  **`lib/screens/analytics_screen.dart`** (line ~115):
  ```dart
  // Before
  const Text('🌸', style: TextStyle(fontSize: 48)),
  const SizedBox(height: 12),
  Text('No expenses this month', ...)

  // After
  MochiWidget(mood: MochiMood.sleepy, size: 80),
  const SizedBox(height: 12),
  Text('No expenses this month', style: GoogleFonts.spaceGrotesk(color: AC.textLight, fontSize: 15)),
  ```

  **`lib/screens/category_details_screen.dart`** (line ~275 — uses `✨` not `🌸`, but same treatment per task spec):
  ```dart
  // Before
  const Text('✨', style: TextStyle(fontSize: 48)),
  const SizedBox(height: 12),
  Text('No expenses yet', ...)

  // After
  MochiWidget(mood: MochiMood.sleepy, size: 80),
  const SizedBox(height: 12),
  Text('No expenses yet', style: GoogleFonts.spaceGrotesk(color: AC.textLight, fontSize: 16)),
  ```

  Add `import '../widgets/mochi_widget.dart';` to each file that doesn't already have it.

  Files:
  - `lib/screens/history_screen.dart`
  - `lib/screens/analytics_screen.dart`
  - `lib/screens/category_details_screen.dart`

  Verify: `flutter analyze lib/` — no new errors. `flutter build apk --debug` completes successfully.

---

## Execution order and dependencies

```
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
```

- Step 1 must come before steps 3, 4, 5, 6, 7 because they all reference the new `AC.heroStart`/`heroEnd` and the new palette values.
- Step 2 (MochiWidget) must come before steps 5, 6, 8 which import it.
- Steps 3 and 4 can technically run in parallel but are sequential here for safety (step 3 modifies many files; having clean fonts before palette work avoids merge confusion).
- Steps 5 and 6 both edit `home_screen.dart` — do them in sequence in the same editing pass.
- Step 7 (nav bar) is independent of steps 5/6.
- Step 8 depends on step 2 (MochiWidget exists) and step 3 (typography already swapped — insert the already-corrected font name).

## Potential analysis errors to watch for

1. **`AppColors` constructor arity.** `AppColors._` is a `const` constructor. Adding `heroStart`/`heroEnd` requires updating both the named-parameter list and both `light`/`dark` constant initialisers. Missing either causes a compile error.
2. **`heroStart`/`heroEnd` referenced before step 1 is complete.** Steps 5/6/7 use `AC.heroStart`; if step 1 is skipped or partial, the analyzer will report undefined getter.
3. **`MochiWidget` import in `home_screen.dart`, `history_screen.dart`, `analytics_screen.dart`, `category_details_screen.dart`.** Each needs `import '../widgets/mochi_widget.dart';` — missing imports are the most common error in step 5, 6, 8.
4. **`spaceMono` with `fontWeight: FontWeight.bold`.** SpaceMono has only Regular and Bold weights. Using `FontWeight.w500`/`w600`/`w700` all resolve to Bold — that is fine. Avoid `w800`/`w900`/`w300` as they will silently fall back to Regular.
5. **`_buildInsights` early return.** The method returns `const SizedBox.shrink()` when there is no insight. The new `MochiWidget` import does not change this — just confirm the return path is untouched.
6. **`withValues(alpha:)` vs `withOpacity`.** The codebase already uses `withValues(alpha:)` throughout (the three remaining `withOpacity` calls are in `add_category_sheet.dart` which is out of scope). Do not introduce `withOpacity` in new code.
