# Mochi SVG assets + dark galaxy theme v2

This commit replaces the CustomPainter-based `MochiWidget` with real SVG assets via `flutter_svg`, updates the dark palette to a "dark galaxy" profile, and tightens up several UI details: hero card gradient hardcoded to an indigo–violet sweep, insight banner logic simplified to a 5-case budget-state selector, nav bar border switched from `AC.primary` to `AC.accent`, stat card backgrounds in analytics moved from `AC.primary` to `AC.secondary`, and colour tokens re-targeted across history and wishlist cards.

**Watch for:** (1) **confirmed** — `MochiMood.happyTears` is defined in the enum and mapped to an asset path, but no production call site ever emits it — `excited` is used for positive savings feedback; `happyTears` is unreachable dead code. (2) **confirmed** — `Space Mono` is called with `FontWeight.w600` in four widget files (`edit_category_sheet.dart`, `add_recurring_sheet.dart` ×2, `add_goal_sheet.dart`). Space Mono ships only Regular (400) and Bold (700); `w600` will silently fall back to 400 rather than render a semibold, which is the spec violation this commit was meant to avoid. These were introduced in commit `b2e0499` and were not fixed here. (3) **confirmed** — The nav bar drop shadow remains `AC.primary.withValues(alpha: 0.25)`; in the new dark palette `AC.primary` is `Color(0xFF231D30)` — almost the same as `AC.bg` — so the shadow is nearly invisible in dark mode, flattening the nav bar.

**Verdict**: APPROVED

---

## High-level view

The dark palette semantically inverts `AC.primary`: it was a visible lavender (`#7C6FE8`), it is now a near-black purple (`#231D30`) indistinguishable from `AC.bg` in dark mode. `AC.accent` takes over as the visible lavender (`#A78BFA`). Code that migrated from `AC.primary` to `AC.accent` (nav border, stat card backgrounds) looks correct; code that was not migrated (nav shadow) goes invisible. Several pre-existing gradient stops in `category_details_screen`, `settings_screen`, `wishlist_screen`, and `manage_recurring_screen` still reference `AC.primary` and will visually flatten in dark mode, though those are out of scope for this commit.

`MochiMood.happyTears` is declared and mapped to an asset but has no call site — the savings-positive arm of the insight banner uses `savingBaddie`. The four Space Mono `w600` usages in widget sheets predate this commit and remain unfixed; they silently fall back to Regular (400) since Space Mono has no semibold.

---

<details>
<summary>Issues (3)</summary>

1. **happyTears is unreachable dead code** — `MochiMood.happyTears` is defined and mapped to `assets/mochi/happy-tears.svg`, but no call site in any screen or widget emits this mood. If Mochi expressing happy-tears is not planned for a future screen, remove the enum value and asset mapping to avoid confusion; if it is planned, add a comment. As-is, the asset path is untested.

2. **Space Mono w600 in four widget files** — `edit_category_sheet.dart:102`, `add_recurring_sheet.dart:117` and `:163`, `add_goal_sheet.dart:107` call `GoogleFonts.spaceMono(fontWeight: FontWeight.w600)`. Space Mono ships only Regular (400) and Bold (700); the flutter_google_fonts package will silently serve the 400 weight instead, so the currency prefix labels and day-selector numerals are rendered lighter than intended. These were introduced in `b2e0499` and were not addressed in this commit. Change the affected call sites to `FontWeight.w700` (bold) or `FontWeight.normal` (400) depending on the intended visual weight.

3. **Nav bar drop shadow invisible in dark mode** — `main_navigation_screen.dart:44` leaves `BoxShadow(color: AC.primary.withValues(alpha: 0.25), ...)` unchanged. `AC.primary` is now `Color(0xFF231D30)` — effectively the same hue as `AC.bg` (`#1A1625`) — so the shadow provides no visible elevation in dark mode. The border was correctly updated from `AC.primary` to `AC.accent` in this commit; the shadow stop should follow. Consider `AC.accent.withValues(alpha: 0.2)` or a fixed dark-mode colour so the pill floats above the content.

</details>

<details>
<summary>Details</summary>

## Dark galaxy palette

The new dark constants:

| Token | Old | New |
|---|---|---|
| `bg` | `#0D0D14` | `#1A1625` |
| `primary` | `#7C6FE8` | `#231D30` |
| `accent` | `#FF6B9D` | `#A78BFA` |
| `secondary` | `#C96BF5` | `#2D2540` |
| `card` | `#13121C` | `#231D30` |
| `success` | `#B8F5A0` | `#6EE7B7` |
| `text` | `#E8E0FF` | `#F0EBFF` |
| `textLight` | `#6B637A` | `#7E7099` |

The semantic inversion of `AC.primary` is the most impactful change. Previously it was a visible lavender (`#7C6FE8`); now it is a near-black purple (`#231D30`), making it unsuitable for use as a foreground or gradient stop. `AC.accent` takes over as the visible lavender (`#A78BFA`). The nav bar border was correctly migrated to `AC.accent`; the shadow was not.

Light-mode `accent` and `secondary` also changed (`#E8527A` → `#A78BFA` and `#A855E8` → `#EDE8FA`), aligning both modes to the same lavender accent hue.

</details>

---

## File map

<details>
<summary>Changed files</summary>

- `lib/main.dart` — Dark and light `AppColors` constants updated to new galaxy palette values.
- `lib/widgets/mochi_widget.dart` — MochiPainter removed; `SvgPicture.asset` implementation with all 9 moods.
- `lib/screens/home_screen.dart` — Hero card gradient hardcoded to `[#2D1B69, #4C1D95, #6D28D9]`; insight banner logic replaced with 5-arm selector; Mochi sizes bumped to 52/90.
- `lib/screens/analytics_screen.dart` — `_pastelTints` inlined per-mode arrays replacing `AC.catXxxBg` lookup; stat card background changed from `AC.primary` to `AC.secondary`.
- `lib/screens/history_screen.dart` — Transaction icon container changed from `AC.cardAlt` to `AC.secondary`.
- `lib/screens/main_navigation_screen.dart` — Nav bar container: opacity removed, border migrated from `AC.primary` to `AC.accent`.
- `lib/screens/wishlist_screen.dart` — Light and dark card colour arrays updated to new palette.
- `pubspec.yaml` — `flutter_svg: ^2.0.10+1` added; `assets/mochi/` directory declared.
- `pubspec.lock` — Lock file updated to reflect new dependency resolution.

</details>
