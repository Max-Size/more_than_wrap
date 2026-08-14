import 'package:flutter/rendering.dart';
import 'package:more_than_wrap/src/overflow/count_builder.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';

/// [ExtendedRenderWrap] that treats the last child as an overflow slot built
/// by [OverflowCountBuilder].
///
/// During [layoutOverflowIndicator] the overflow count is written onto
/// [RenderOverflowCountBuilder] and the child is laid out immediately, so the
/// builder runs inside this same [performLayout] pass (LayoutBuilder pattern).
class ExtendedRenderWrapWidgetBuilder extends ExtendedRenderWrap<void> {
  ExtendedRenderWrapWidgetBuilder({
    required super.runSpacing,
    required super.spacing,
    required super.isOverflowWidgetAdded,
    super.children,
    super.maxLines,
  });

  void _layoutOverflowChild(RenderBox overflowRender, int count) {
    if (overflowRender is RenderOverflowCountBuilder) {
      final slot = overflowRender;
      if (slot.overflowCount != count) {
        // Mutating a descendant's layout flags is only allowed inside
        // [invokeLayoutCallback] (same mechanism LayoutBuilder uses).
        invokeLayoutCallback<BoxConstraints>((_) {
          slot.overflowCount = count;
          // Force a second [performLayout] in this same parent pass when
          // constraints did not change (otherwise [layout] would no-op).
          slot.markNeedsLayout();
        });
      }
    }
    overflowRender.layout(constraints, parentUsesSize: true);
    final childParentData = overflowRender.parentData as LimitWrapParentData;
    childParentData.offset = Offset(dx, dy);
  }

  /// Frees space for the overflow indicator by hiding the last visible child.
  ///
  /// Returns whether a child was hidden (and [objectsOverflowed] incremented).
  bool _hideLastVisibleChild(RenderBox overflowRender) {
    final last = lastRenderedChild;
    if (last == null) {
      return false;
    }

    dx -= last.size.width + spacing;

    // If that child alone occupied the last row, try placing the overflow
    // indicator on the previous row after the penultimate child.
    if (dx == 0 &&
        penultimateRenderedChildOffset != null &&
        penultimateRenderedChild != null) {
      overflowRender.layout(constraints, parentUsesSize: true);
      final size = overflowRender.size;
      final potentialEnd =
          penultimateRenderedChildOffset!.dx +
          penultimateRenderedChild!.size.width +
          spacing +
          size.width;

      if (potentialEnd <= constraints.maxWidth) {
        dx =
            penultimateRenderedChildOffset!.dx +
            penultimateRenderedChild!.size.width +
            spacing;
        dy -= penultimateRenderedChild!.size.height + runSpacing;
      }
    }

    last.layout(
      ExtendedRenderWrap.shrinkedConstraints,
      parentUsesSize: true,
    );
    objectsOverflowed++;
    return true;
  }

  @override
  void layoutOverflowIndicator(bool hasOverflow) {
    if (!isOverflowWidgetAdded) {
      return;
    }
    final overflowRender = lastChild;
    if (overflowRender == null) {
      return;
    }

    if (!hasOverflow) {
      if (overflowRender is RenderOverflowCountBuilder) {
        final slot = overflowRender;
        if (slot.overflowCount != 0) {
          invokeLayoutCallback<BoxConstraints>((_) {
            slot.overflowCount = 0;
            slot.markNeedsLayout();
          });
        }
      }
      overflowRender.layout(
        ExtendedRenderWrap.shrinkedConstraints,
        parentUsesSize: true,
      );
      return;
    }

    // Pass 1: build + layout overflow with the count from the wrap pass.
    _layoutOverflowChild(overflowRender, objectsOverflowed);

    final endX = dx + overflowRender.size.width;
    final needsRoom =
        endX > constraints.maxWidth || objectsOverflowed == 1;

    if (needsRoom) {
      // Pass 2 (same frame): hide one more child and rebuild with count+1.
      _hideLastVisibleChild(overflowRender);
      _layoutOverflowChild(overflowRender, objectsOverflowed);
    }
  }
}
