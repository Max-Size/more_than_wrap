<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# more_than_wrap

A Flutter package that provides a custom `Wrap`-like layout with a limited number of rows and an optional overflow indicator.

## Features

- **Limited rows**: Restrict the layout to a maximum number of lines
- **Two overflow strategies**:
  - **Styler API**: draw a compact indicator (text) directly on canvas via `overflowBuilderStyle`
  - **Builder API**: provide your own `Widget` via `LimitedWrapWidget.builder`
- **Flexible spacing**: Configure `spacing` and `runSpacing`
- **Overflow count**: Both strategies receive the number of overflowed children

> Warning: The current release is experimental and may cause visible UI jank in certain cases (see details below).

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  more_than_wrap: ^0.0.1
```

Then run:
```bash
flutter pub get
```

## Usage

### Option A: Styler API (drawn indicator via `overflowBuilderStyle`)

Use `LimitedWrapWidget` with `overflowBuilderStyle` to draw a compact text indicator (for example, "+3"). This indicator is not a separate child; it is painted directly by the render object.

```dart
import 'package:flutter/material.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

LimitedWrapWidget(
  maxLines: 2,
  spacing: 8,
  runSpacing: 4,
  overflowBuilderStyle: OverflowBuilderStyle(
    textBuilder: (count) => '+$count',
    textStyle: const TextStyle(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    radius: const Radius.circular(12),
    color: Colors.blue,
    // Optional: tap handling for the painted indicator
    onTap: () {
      // Handle tap on the overflow indicator
    },
  ),
  children: const [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    Chip(label: Text('Tag 3')),
    // ...
  ],
)
```

When overflow occurs, the indicator will be painted at the end of the last visible row. The `textBuilder` receives the number of overflowed children.

### Option B: Builder API (custom widget via `LimitedWrapWidget.builder`)

Use `LimitedWrapWidget.builder` to supply your own overflow widget (e.g., a `Chip`). In this mode, the overflow indicator is added as a real child at the end.

```dart
import 'package:flutter/material.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

LimitedWrapWidget.builder(
  maxLines: 2,
  spacing: 8,
  runSpacing: 4,
  overflowWidgetBuilder: (count) {
    if (count == null || count == 0) return const SizedBox.shrink();
    return Chip(
      label: Text('+$count more'),
      backgroundColor: Colors.grey.shade300,
    );
  },
  children: const [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    Chip(label: Text('Tag 3')),
    // ...
  ],
)
```

## Stability and known issues

- The current implementation of `LimitedWrapWidget.builder` is **unstable** and may cause visible UI jank (e.g., slight layout shifts during measurement/paint) in some scenarios.
- This applies to both strategies (Styler and Builder), but may be more noticeable when the overflow state changes frequently.

We recommend testing your target screens carefully and avoiding heavy rebuilds of the overflow indicator where possible or just use plain `LimitedWrapWidget` with no worries.

## Roadmap

- A future, more stable variant of `LimitedWrapWidget` is planned as soon as possible. It will:
  - Provide a more robust layout mechanism that minimizes jank
  - Offer a convenient `Widget` API with a `builder`-like property while keeping the flexibility of the current design

If you have specific stability requirements or API suggestions, please open an issue.

### Contributing

Feel free to contribute to this package by:
- Reporting bugs
- Suggesting new features
- Submitting pull requests

### License

This package is licensed under the BSD 3-Clause License. See the OSI page: [BSD-3-Clause](https://opensource.org/licenses/BSD-3-Clause).
