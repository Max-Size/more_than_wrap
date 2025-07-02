import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow_style.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';
import 'package:more_than_wrap/src/render_box/styler.dart';
import 'package:more_than_wrap/src/render_widgets/render_widget.dart';

class LimitedWrapWidgetStyler extends LimitedWrap<String> {
  final OverflowBuilderStyle? overflowBuilderStyle;

  const LimitedWrapWidgetStyler({
    super.key,
    required super.children,
    this.overflowBuilderStyle,
    super.maxLines,
    super.spacing = 0,
    super.runSpacing = 0,
    super.onWidgetsLayouted,
  });

  @override
  ExtendedRenderWrap<String> createRenderObject(BuildContext context) {
    return ExtendedRenderWrapWidgetStyler(
      runSpacing: runSpacing,
      spacing: spacing,
      onWidgetsLayouted: onWidgetsLayouted,
      maxLines: maxLines,
      overflowBuilderStyle: overflowBuilderStyle,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant ExtendedRenderWrapWidgetStyler renderObject,
  ) {
    renderObject.overflowBuilderStyle = overflowBuilderStyle;
    super.updateRenderObject(context, renderObject);
  }
}
