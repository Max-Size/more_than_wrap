import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';

/// Custom [MultiChildRenderObjectWidget] for creating
/// [Wrap] with limited number of rows
///
abstract class LimitedWrap<T> extends MultiChildRenderObjectWidget {
  /// Maximum number of rows
  final int? maxLines;

  /// Distance between elements in a row
  final double spacing;

  /// Distance between rows
  final double runSpacing;

  /// Function that will be called when the
  /// number of overflowed elements becomes known
  ///
  final T Function(int amountOfOverflowedWidgets)? onWidgetsLayouted;

  const LimitedWrap({
    super.key,
    required super.children,
    this.maxLines,
    this.spacing = 0,
    this.runSpacing = 0,
    this.onWidgetsLayouted,
  });

  /// Create custom [RenderObject]
  @override
  ExtendedRenderWrap<T> createRenderObject(BuildContext context);

  /// Update custom [RenderObject]
  @override
  void updateRenderObject(
    BuildContext context,
    covariant ExtendedRenderWrap renderObject,
  ) {
    renderObject
      ..onWidgetsLayoutedInternal = onWidgetsLayouted
      ..maxLines = maxLines;
    renderObject.onUpdate();
  }
}
