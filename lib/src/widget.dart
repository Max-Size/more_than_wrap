import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/count_builder.dart';
import 'package:more_than_wrap/src/extended_wrap.dart';

export 'package:more_than_wrap/src/count_builder.dart'
    show LimitedWrapOverflowBuilder;

/// A [Wrap]-like widget with a maximum number of rows and an overflow indicator.
///
/// [overflowWidgetBuilder] is invoked during layout with the number of children
/// that did not fit (same-frame rebuild, no post-layout flicker).
class LimitedWrapWidget extends StatelessWidget {
  const LimitedWrapWidget({
    super.key,
    required this.children,
    required this.overflowWidgetBuilder,
    this.spacing = 0,
    this.runSpacing = 0,
    this.maxLines,
  });

  /// Wrap items (the overflow slot is appended automatically).
  final List<Widget> children;

  /// Builds the overflow indicator from the hidden-child count.
  final LimitedWrapOverflowBuilder overflowWidgetBuilder;

  /// Horizontal gap between items in a row.
  final double spacing;

  /// Vertical gap between rows.
  final double runSpacing;

  /// Maximum number of rows. `null` means unlimited.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ExtendedWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      maxLines: maxLines,
      children: [
        ...children,
        OverflowCountBuilder(builder: overflowWidgetBuilder),
      ],
    );
  }
}
