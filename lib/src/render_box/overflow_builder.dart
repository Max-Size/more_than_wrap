import 'dart:ui';

import 'package:more_than_wrap/src/render_box/render_box.dart';

class ExtendedRenderWrapWidgetBuilder extends ExtendedRenderWrap<void> {
  ExtendedRenderWrapWidgetBuilder({
    required super.runSpacing,
    required super.spacing,
    required super.isOverflowWidgetAdded,
    super.children,
    super.onWidgetsLayouted,
    super.maxLines,
  });

  @override
  void layoutOverflowIndicator(bool hasOverflow) {
    final overflowRender = lastChild;
    if (!hasOverflow) {
      overflowRender?.layout(
        ExtendedRenderWrap.shrinkedConstraints,
        parentUsesSize: true,
      );
    } else {
      if (isHideLastItemIfOverflowed) {
        dx -= lastRenderedChild!.size.width + spacing;

        /// Case when dx == 0 is possible if child on last row occupied all width,
        /// in such case move overflow widget to previous row and shift right
        /// on width of widget from previous row
        if (dx == 0 &&
            penultimateRenderedChildOffset != null &&
            penultimateRenderedChild != null) {
          overflowRender?.layout(constraints, parentUsesSize: true);
          final size = overflowRender!.size;

          final potentialXOverflowWidgetEndOffset =
              penultimateRenderedChildOffset?.dx ??
              0 +
                  (penultimateRenderedChild?.size.width ?? 0) +
                  spacing +
                  size.width;

          /// If overflow widget does not go beyond border, then shift it
          if (potentialXOverflowWidgetEndOffset <= constraints.maxWidth) {
            dx +=
                penultimateRenderedChildOffset?.dx ??
                0 + (penultimateRenderedChild?.size.width ?? 0) + spacing;
            dy -= (penultimateRenderedChild?.size.height ?? 0) + runSpacing;
          }
        }
        lastRenderedChild?.layout(
          ExtendedRenderWrap.shrinkedConstraints,
          parentUsesSize: true,
        );
      }
      if (!calculatedOverflow) {
        Future.microtask(() {
          calculatedOverflow = true;
          onWidgetsLayoutedInternal?.call(objectsOverflowed);
          objectsOverflowed = 0;
        });
      }

      overflowRender?.layout(constraints, parentUsesSize: true);
      final childParentData =
          overflowRender?.parentData as LimitWrapParentData?;
      childParentData?.offset = Offset(dx, dy);

      /// More reliable condition, but answers less requirements
      /// In case of critical bugs return its use
      ///
      ///if(childParentData!.offset.dx + overflowRender!.size.width > constraints.maxWidth && calculatedOverflow)
      final endOverflowRenderXOffset =
          childParentData!.offset.dx + overflowRender!.size.width;
      if ((endOverflowRenderXOffset > constraints.maxWidth ||
              objectsOverflowed == 1) &&
          calculatedOverflow) {
        isHideLastItemIfOverflowed = true;
        objectsOverflowed++;
        Future.microtask(() {
          onWidgetsLayoutedInternal?.call(objectsOverflowed);
          objectsOverflowed = 0;
        });
      }
    }
  }
}
