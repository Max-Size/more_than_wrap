import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow/builder.dart';
import 'package:more_than_wrap/src/overflow/item.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';
import 'package:more_than_wrap/src/render_box/styler.dart';
import 'package:more_than_wrap/src/render_widgets/render_widget.dart';

class LimitedWrapWidgetStyler extends LimitedWrap<String> {
  final OverflowBuilder? overflowBuilder;

  final int _amountOfActualWrapChildren;

  LimitedWrapWidgetStyler({
    super.key,
    required List<Widget> children,
    this.overflowBuilder,
    super.maxLines,
    super.spacing = 0,
    super.runSpacing = 0,
  }) : _amountOfActualWrapChildren = children.length,
       super(
         children: [
           ...children,
           ...overflowBuilder?.items.whereType<OverflowBuilderWidgetItem>().map(
                 (e) => e.child,
               ) ??
               [],
         ],
       );

  @override
  ExtendedRenderWrap<String> createRenderObject(BuildContext context) {
    return ExtendedRenderWrapWidgetStyler(
      runSpacing: runSpacing,
      spacing: spacing,
      maxLines: maxLines,
      overflowBuilderStyle: overflowBuilder,
      amountOfActualWrapChildren: _amountOfActualWrapChildren,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant ExtendedRenderWrapWidgetStyler renderObject,
  ) {
    renderObject.amountOfActualWrapChildren = _amountOfActualWrapChildren;
    renderObject.overflowBuilderStyle = overflowBuilder;
    super.updateRenderObject(context, renderObject);
  }
}
