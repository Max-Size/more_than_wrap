import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow_style.dart';
import 'package:more_than_wrap/src/render_widgets/builder.dart';
import 'package:more_than_wrap/src/render_widgets/styler.dart';

/// Builder function for overflow widget
///
typedef OnWidgetsLayouted = Widget Function(int? amountOfOverflowedWidgets);

/// Custom [Wrap] widget with limited number of rows and
/// optional widget for overflow display
///
class LimitedWrapWidget extends StatefulWidget {
  /// Children widgets
  final List<Widget> children;

  /// Builder function for overflow widget
  final OnWidgetsLayouted? overflowWidgetBuilder;

  /// Spacing between elements in a row
  final double spacing;

  /// Spacing between rows
  final double runSpacing;

  /// Maximum number of rows
  final int? maxLines;

  /// Style for overflow widget
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
    this.overflowWidgetBuilder,
    required this.children,
    required this.spacing,
    required this.runSpacing,
    this.maxLines,
  }) : overflowBuilderStyle = null;

  @override
  State<LimitedWrapWidget> createState() => _LimitedWrapWidgetState();
}

class _LimitedWrapWidgetState extends State<LimitedWrapWidget> {
  /// Notifier that will call [widget.overflowWidgetBuilder] when receiving
  /// the number of overflowed elements
  ///
  final amountOfOverflowedWidgetsNotifier = ValueNotifier<int?>(null);

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
    final overflowBuilder = widget.overflowWidgetBuilder;
    if (overflowBuilder != null) {
      final overflowWidget = widget.overflowWidgetBuilder != null
          ? ValueListenableBuilder<int?>(
              valueListenable: amountOfOverflowedWidgetsNotifier,
              builder: (context, value, child) =>
                  widget.overflowWidgetBuilder!(value),
            )
          : null;

      final widgets = [
        ...widget.children,
        if (overflowWidget != null) overflowWidget,
      ];

      return LimitedWrapWidgetBuilder(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        maxLines: widget.maxLines,
        onWidgetsLayouted: (amountOfOverflowedWidgets) {
          amountOfOverflowedWidgetsNotifier.value = amountOfOverflowedWidgets;
        },
        isOverflowWidgetAdded: overflowWidget != null,
        children: widgets,
      );
    } else {
      return LimitedWrapWidgetStyler(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        maxLines: widget.maxLines,
        overflowBuilderStyle: widget.overflowBuilderStyle,
        onWidgetsLayouted: widget.overflowBuilderStyle?.textBuilder,
        children: widget.children,
      );
    }
  }

  @override
  void dispose() {
    amountOfOverflowedWidgetsNotifier.dispose();
    super.dispose();
  }
}
