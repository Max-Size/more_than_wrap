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

A Flutter package that provides a custom `Wrap` widget with limited number of rows and optional overflow widget display.

## Features

- **Limited Rows**: Set a maximum number of rows for the wrap layout
- **Overflow Handling**: Display a custom widget when content overflows
- **Flexible Spacing**: Configure spacing between elements and rows
- **Real-time Updates**: Get notified when overflow occurs with the number of overflowed elements

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

### Basic Usage

```dart
import 'package:more_than_wrap/more_than_wrap.dart';

LimitedWrapWidget(
  maxLines: 2, // Maximum 2 rows
  spacing: 8.0, // Spacing between elements
  runSpacing: 4.0, // Spacing between rows
  children: [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    Chip(label: Text('Tag 3')),
    // ... more widgets
  ],
)
```

### With Overflow Widget

```dart
LimitedWrapWidget(
  maxLines: 2,
  spacing: 8.0,
  runSpacing: 4.0,
  overflowWidgetBuilder: (overflowCount) {
    return Chip(
      label: Text('+$overflowCount more'),
      backgroundColor: Colors.grey[300],
    );
  },
  children: [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    // ... more widgets
  ],
)
```

### Advanced Usage with Callback

```dart
LimitedWrapWidget(
  maxLines: 3,
  spacing: 12.0,
  runSpacing: 8.0,
  overflowWidgetBuilder: (overflowCount) {
    if (overflowCount == null) return SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        // Handle overflow tap
        print('$overflowCount items overflowed');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '+$overflowCount',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  },
  children: yourWidgetList,
)
```

## Additional information

This package is useful for:
- Tag clouds with limited height
- Chip lists that need to fit in constrained spaces
- Any layout where you want to show a limited number of rows with overflow indication

### Key Components

- `LimitedWrapWidget`: The main widget that provides the limited wrap functionality
- `OnWidgetsLayouted`: Callback function type for overflow notifications
- Custom render objects for efficient layout calculations

### Contributing

Feel free to contribute to this package by:
- Reporting bugs
- Suggesting new features
- Submitting pull requests

### License

This package is licensed under the MIT License.
