# ✨ more_than_wrap

<p align="center">
  <strong>Wrap with a row limit — and a real <code>+N more</code> widget.</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/more_than_wrap"><img src="https://img.shields.io/pub/v/more_than_wrap.svg?style=for-the-badge&color=0175C2" alt="pub package"></a>
  <a href="https://max-size.github.io/more_than_wrap/"><img src="https://img.shields.io/badge/🎮_live_demo-play-FF6D00?style=for-the-badge" alt="live demo"></a>
  <a href="https://opensource.org/licenses/BSD-3-Clause"><img src="https://img.shields.io/badge/license-BSD--3--Clause-8A2BE2?style=for-the-badge" alt="license"></a>
</p>

Flutter's `Wrap` will happily grow forever. **more_than_wrap** stops after `maxLines` and drops a real overflow child at the end of the last row — a chip, a button, whatever you build.

Only children that fit are mounted. Hidden items never sit in the tree. The overflow indicator is built **during layout**, so the first frame already has the correct count. No flash. No jump.

<p align="center">
  <img src="https://raw.githubusercontent.com/Max-Size/more_than_wrap/main/screenshots/overflow-chips.png" alt="Chip tags capped at two rows with a real +5 more overflow child" width="560">
</p>

> 🎯 **Flutter 3.32+** required · [**Try the live demo →**](https://max-size.github.io/more_than_wrap/)

---

## 🌈 Features

| | |
| --- | --- |
| 📏 **Limited rows** | `maxLines` caps the height. Pass `null` and it behaves like a regular `Wrap`. |
| 💎 **Real overflow widget** | `+3 more`, a chip, a tappable button — it's a normal child, not canvas text. |
| 🦥 **Lazy inflate** | Overflowed children are **unmounted**. `.builder` doesn't even construct them. |
| 🎬 **Correct first frame** | Overflow is measured and rebuilt in the **same** layout pass. |
| 🧩 **Fits the indicator** | If `+N` is too wide, more children hide until it fits. |
| 🧭 **Wrap-compatible packing** | `spacing`, `runSpacing`, `alignment`, `runAlignment`, `crossAxisAlignment`, RTL, `clipBehavior`. |

Direction is always **horizontal** (`Wrap` with `direction: Axis.horizontal`). Vertical wrap is out of scope.

Perfect for tag clouds, filter chips, avatar stacks, compact label rows.

---

## 🚀 Getting started

```yaml
dependencies:
  more_than_wrap: ^1.0.0
```

```bash
flutter pub get
```

That's it. Import and wrap.

---

## 🧪 Usage

### 📦 Children list

Widgets in `children` are created up front; only those that fit are **mounted**.

```dart
import 'package:flutter/material.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

LimitedWrap(
  maxLines: 2,
  spacing: 8,
  runSpacing: 4,
  overflowWidgetBuilder: (context, count) {
    return Chip(label: Text('+$count more'));
  },
  children: [
    for (final tag in tags) Chip(label: Text(tag)),
  ],
)
```

### 🏗️ Builder (lazy children)

`itemBuilder` runs only for indices that need to be measured or shown. Everything past the visible prefix is never built.

```dart
LimitedWrap.builder(
  maxLines: 2,
  spacing: 8,
  runSpacing: 4,
  itemCount: tags.length,
  itemBuilder: (context, index) {
    return Chip(label: Text(tags[index]));
  },
  overflowWidgetBuilder: (context, count) {
    return ActionChip(
      label: Text('+$count more'),
      onPressed: () {
        // Expand, open a sheet, navigate, …
      },
    );
  },
)
```

> 💡 **Rule of thumb:** `.builder` for long / expensive lists. The list constructor when the set is small and already in memory.

### 💥 Overflow widget

`overflowWidgetBuilder` is optional. Without it, children that do not fit are unmounted and nothing is shown in their place.

When provided, it is a `LimitedWrapOverflowBuilder`:

```dart
typedef LimitedWrapOverflowBuilder = Widget Function(
  BuildContext context,
  int overflowCount,
);
```

- Called **only** when at least one child does not fit
- `overflowCount` is always `> 0`
- Not called at all when everything fits — the overflow slot is not even mounted
- The returned widget is a **normal child**: layout, hit testing, animation — all work

If the indicator is wider than the leftover space on the last row, `LimitedWrap` hides more children (and bumps the count) until it fits. If that empties the last row and the indicator fits on the previous one — it moves there.

### ♾️ Unlimited rows

Omit `maxLines` (or pass `null`) to wrap like a regular `Wrap`. You can also omit `overflowWidgetBuilder` — overflowed children are simply not mounted.

```dart
LimitedWrap(
  spacing: 8,
  runSpacing: 4,
  children: chips,
)
```

### 🎨 Alignment (same names as `Wrap`)

```dart
LimitedWrap(
  maxLines: 2,
  alignment: WrapAlignment.end,
  runAlignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  textDirection: TextDirection.rtl,
  verticalDirection: VerticalDirection.down,
  clipBehavior: Clip.hardEdge,
  overflowWidgetBuilder: (context, count) => Text('+$count'),
  children: chips,
)
```

| Parameter | What it does |
| --- | --- |
| `spacing` | ↔️ Gap between children in a row |
| `runSpacing` | ↕️ Gap between rows |
| `alignment` | Main-axis packing inside a row (`start`, `end`, `center`, `spaceBetween`, …) |
| `runAlignment` | Where the rows sit if there is extra height |
| `crossAxisAlignment` | Align children within a row (`start`, `end`, `center`) |
| `textDirection` | LTR / RTL — defaults to ambient `Directionality` |
| `verticalDirection` | `down` (first row on top) or `up` |
| `clipBehavior` | Clip if content overflows the incoming constraints |

---

## ⚙️ How it works

`LimitedWrap` is not a thin wrapper around `Wrap`. It's a `RenderObjectWidget` that inflates children **during layout**, in the spirit of slivers:

1. 🧱 Children are created from the start of the list until `maxLines` is filled.
2. 🙈 Remaining items stay unmounted (`overflowCount = itemCount - placedCount`).
3. 🎰 If `overflowCount > 0` and `overflowWidgetBuilder` is set, an overflow slot is inserted and the builder runs **inside** `performLayout` (same idea as `LayoutBuilder`). Without a builder, overflowed children are simply left unmounted.
4. 🔁 If the overflow widget still doesn't fit, the last visible child is unmounted, the count goes up, and the indicator is laid out again — **still in that layout pass**.
5. 📐 Positions then follow `RenderWrap` packing for a horizontal wrap.

Because the overflow widget is built in-layout, the first paint already has the correct `+N`. No one-frame flash of a wrong count. No hiding overflowed widgets with opacity or `Offstage`.

> ⚠️ **Intrinsic dimensions** of the overflow slot are not supported (same limitation as `LayoutBuilder`). Give the indicator a concrete size, or let it size itself from the wrap's `maxWidth`.

---

## 🎮 Example

The [example](https://github.com/Max-Size/more_than_wrap/tree/main/example) app is a playground: tweak max lines, item width, and item count live. The web build is the [**live demo**](https://max-size.github.io/more_than_wrap/).

```bash
cd example
flutter run
```

---

## 📬 Additional information

- 📚 [API reference](https://pub.dev/documentation/more_than_wrap/latest/)
- 🐛 [Issue tracker](https://github.com/Max-Size/more_than_wrap/issues)
- 💻 [Source](https://github.com/Max-Size/more_than_wrap)

Bug reports and PRs are very welcome. Need vertical wrap (`direction: Axis.vertical`) or intrinsic sizing of the overflow slot? [Open an issue](https://github.com/Max-Size/more_than_wrap/issues).

### 📄 License

BSD 3-Clause. See [LICENSE](https://github.com/Max-Size/more_than_wrap/blob/main/LICENSE) and [BSD-3-Clause](https://opensource.org/licenses/BSD-3-Clause).
