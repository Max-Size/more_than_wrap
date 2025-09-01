import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow/builder.dart';
import 'package:more_than_wrap/src/overflow/style.dart';
import 'package:more_than_wrap/src/render_widgets/styler.dart';

/// Custom [Wrap] widget with limited number of rows and
/// optional widget for overflow display
///
class LimitedWrapWidget extends StatelessWidget {
  /// Children widgets
  final List<Widget> children;

  /// Spacing between elements in a row
  final double spacing;

  /// Spacing between rows
  final double runSpacing;

  /// Maximum number of rows
  final int? maxLines;

  /// Style for overflow widget
  final OverflowBuilder? overflowBuilder;

  const LimitedWrapWidget({
    super.key,
    required this.overflowBuilder,
    required this.children,
    required this.spacing,
    required this.runSpacing,
    this.maxLines,
  });

  /// Wrap [widget.overflowWidgetBuilder] in [ValueListenableBuilder]
  /// to rebuild the widget when a new value becomes known
  /// for the number of overflowed elements
  ///
  /// When the `onWidgetsLayouted` function is called, the notifier will receive
  /// a new value `amountOfOverflowedWidgets` for the number of
  /// overflowed elements, which will trigger a rebuild
  /// of the overflow widget
  ///
  @override
  Widget build(BuildContext context) {
    return LimitedWrapWidgetStyler(
      spacing: spacing,
      runSpacing: runSpacing,
      maxLines: maxLines,
      overflowBuilder: overflowBuilder,
      children: children,
    );
  }
}
