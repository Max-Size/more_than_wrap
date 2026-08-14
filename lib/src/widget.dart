import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow/count_builder.dart';
import 'package:more_than_wrap/src/overflow_style.dart';
import 'package:more_than_wrap/src/render_widgets/builder.dart';
import 'package:more_than_wrap/src/render_widgets/styler.dart';

export 'package:more_than_wrap/src/overflow/count_builder.dart'
    show LimitedWrapOverflowBuilder;

/// Custom [Wrap] with a max row count and an overflow indicator.
///
/// Use [LimitedWrapWidget.builder] when the overflow UI is a real [Widget]
/// built from the overflow count (no flicker: rebuild runs during layout).
///
/// Use the default constructor with [overflowBuilderStyle] for the lightweight
/// canvas-drawn indicator.
class LimitedWrapWidget extends StatelessWidget {
  /// Children widgets
  final List<Widget> children;

  /// Builds the overflow indicator from the number of hidden children.
  ///
  /// Called during layout (same frame), not via a post-layout [ValueNotifier].
  final LimitedWrapOverflowBuilder? overflowWidgetBuilder;

  /// Spacing between elements in a row
  final double spacing;

  /// Spacing between rows
  final double runSpacing;

  /// Maximum number of rows
  final int? maxLines;

  /// Style for the canvas-drawn overflow indicator (default constructor).
  final OverflowBuilderStyle? overflowBuilderStyle;

  const LimitedWrapWidget({
    super.key,
    required this.overflowBuilderStyle,
    required this.children,
    required this.spacing,
    required this.runSpacing,
    this.maxLines,
  }) : overflowWidgetBuilder = null;

  const LimitedWrapWidget.builder({
    super.key,
    required this.overflowWidgetBuilder,
    required this.children,
    required this.spacing,
    required this.runSpacing,
    this.maxLines,
  }) : overflowBuilderStyle = null;

  @override
  Widget build(BuildContext context) {
    final overflowBuilder = overflowWidgetBuilder;
    if (overflowBuilder != null) {
      return LimitedWrapWidgetBuilder(
        spacing: spacing,
        runSpacing: runSpacing,
        maxLines: maxLines,
        isOverflowWidgetAdded: true,
        children: [
          ...children,
          // Slot rebuilt during performLayout when the wrap knows the count.
          OverflowCountBuilder(builder: overflowBuilder),
        ],
      );
    }

    return LimitedWrapWidgetStyler(
      spacing: spacing,
      runSpacing: runSpacing,
      maxLines: maxLines,
      overflowBuilderStyle: overflowBuilderStyle,
      onWidgetsLayouted: overflowBuilderStyle?.textBuilder,
      children: children,
    );
  }
}
