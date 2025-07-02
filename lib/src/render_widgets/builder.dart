import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/render_box/overflow_builder.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';
import 'package:more_than_wrap/src/render_widgets/render_widget.dart';

class LimitedWrapWidgetBuilder extends LimitedWrap<void> {
  final bool isOverflowWidgetAdded;

  const LimitedWrapWidgetBuilder({
    super.key,
    required this.isOverflowWidgetAdded,
    required super.children,
    super.maxLines,
    super.spacing = 0,
    super.runSpacing = 0,
    super.onWidgetsLayouted,
  });

  @override
  ExtendedRenderWrap<void> createRenderObject(BuildContext context) {
    return ExtendedRenderWrapWidgetBuilder(
      runSpacing: runSpacing,
      spacing: spacing,
      isOverflowWidgetAdded: isOverflowWidgetAdded,
      onWidgetsLayouted: onWidgetsLayouted,
      maxLines: maxLines,
    );
  }
}
