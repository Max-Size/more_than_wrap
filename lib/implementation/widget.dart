part of '../more_than_wrap.dart';

/// Builder function for overflow widget
///
typedef OnWidgetsLayouted = Widget Function(int? amountOfOverflowedWidgets);

/// Custom [Wrap] widget with limited number of rows and
/// optional widget for overflow display
///
class LimitedWrapWidget extends StatelessWidget {
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

  /// Notifier that will call [overflowWidgetBuilder] when receiving
  /// the number of overflowed elements
  ///
  final amountOfOverflowedWidgetsNotifier = ValueNotifier<int?>(null);

  LimitedWrapWidget({
    super.key,
    this.overflowWidgetBuilder,
    required this.children,
    required this.spacing,
    required this.runSpacing,
    this.maxLines,
  });

  /// Wrap [overflowWidgetBuilder] in [ValueListenableBuilder]
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
    final overflowWidget = overflowWidgetBuilder != null
        ? ValueListenableBuilder<int?>(
            valueListenable: amountOfOverflowedWidgetsNotifier,
            builder: (context, value, child) => overflowWidgetBuilder!(value),
          )
        : null;

    final widgets = [
      ...children,
      if (overflowWidget != null) overflowWidget,
    ];

    return LimitedWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      maxLines: maxLines,
      onWidgetsLayouted: (amountOfOverflowedWidgets) {
        amountOfOverflowedWidgetsNotifier.value = amountOfOverflowedWidgets;
      },
      isOverflowedWidgetAdded: overflowWidget != null,
      children: widgets,
    );
  }
}
