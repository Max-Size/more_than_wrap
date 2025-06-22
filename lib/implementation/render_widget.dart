part of '../more_than_wrap.dart';

/// Custom [MultiChildRenderObjectWidget] for creating
/// [Wrap] with limited number of rows
///
class LimitedWrap extends MultiChildRenderObjectWidget {
  /// Maximum number of rows
  final int? maxLines;

  /// Distance between elements in a row
  final double spacing;

  /// Distance between rows
  final double runSpacing;

  /// Widget that will be displayed on overflow
  final Widget? overflowWidget;

  /// Function that will be called when the
  /// number of overflowed elements becomes known
  ///
  final void Function(int amountOfOverflowedWidgets)? onWidgetsLayouted;

  /// Flag determining if overflow widget is added
  final bool isOverflowedWidgetAdded;

  LimitedWrap({
    super.key,
    required List<Widget> children,
    this.maxLines,
    this.spacing = 0,
    this.runSpacing = 0,
    this.overflowWidget,
    this.onWidgetsLayouted,
    required this.isOverflowedWidgetAdded,
  }) : super(
         children: [...children, if (overflowWidget != null) overflowWidget],
       );

  /// Create custom [RenderObject]
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ExtendedRenderWrap(
      runSpacing: runSpacing,
      spacing: spacing,
      maxLines: maxLines,
      onWidgetsLayouted: onWidgetsLayouted,
      isOverflowWidgetAdded: isOverflowedWidgetAdded,
    );
  }

  /// Update custom [RenderObject]
  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    covariant _ExtendedRenderWrap renderObject,
  ) {
    renderObject
      ..onWidgetsLayouted = onWidgetsLayouted
      ..maxLines = maxLines;
    renderObject.onUpdate();
  }
}
