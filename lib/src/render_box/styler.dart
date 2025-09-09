import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:more_than_wrap/src/overflow/builder.dart';
import 'package:more_than_wrap/src/overflow/item.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';

class _DrawResult {
  final Picture picture;
  final Size size;

  _DrawResult({required this.picture, required this.size});
}

class ExtendedRenderWrapWidgetStyler extends ExtendedRenderWrap<String> {
  OverflowBuilder? _overflowBuilder;
  _DrawResult? _overflowIndicator;
  Rect? _gestureTarget;

  ExtendedRenderWrapWidgetStyler({
    required OverflowBuilder? overflowBuilderStyle,
    required super.runSpacing,
    required super.spacing,
    super.children,
    super.onWidgetsLayouted,
    super.maxLines,
    required super.amountOfActualWrapChildren,
  }) : _overflowBuilder = overflowBuilderStyle,
       super(isOverflowWidgetAdded: false);

  set overflowBuilderStyle(OverflowBuilder? overflowBuilderStyle) {
    _overflowBuilder = overflowBuilderStyle;
    markNeedsLayout();
  }

  _DrawResult _drawOverflowIndicator(
    int objectsOverflowed,
    OverflowBuilder overflowBuilder,
  ) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paddingHorizontal = overflowBuilder.style.padding.horizontal;
    final childrenSize = _layoutOverflowChildren(canvas, objectsOverflowed);
    final overflowWidth = childrenSize.width + paddingHorizontal;
    final overflowHeight =
        childrenSize.height + overflowBuilder.style.padding.vertical;
    final radius = overflowBuilder.style.radius ?? Radius.zero;
    final overflowRect = RRect.fromLTRBR(
      0,
      0,
      overflowWidth,
      overflowHeight,
      radius,
    );
    canvas.drawRRect(
      overflowRect,
      Paint()
        ..color =
            overflowBuilder.style.color ??
            const Color.fromARGB(255, 145, 128, 128),
    );
    final border = overflowBuilder.style.border;
    if (border != null) {
      border.paint(
        canvas,
        overflowRect.outerRect,
        textDirection: TextDirection.ltr,
        borderRadius: BorderRadius.all(radius),
      );
    }

    final size = Size(overflowWidth, overflowHeight);
    final picture = recorder.endRecording();

    return _DrawResult(picture: picture, size: size);
  }

  @override
  Size layoutOverflowIndicator(bool hasOverflow) {
    if (!hasOverflow) {
      _overflowIndicator = null;
    }
    final overflowBuilder = _overflowBuilder;
    if (!hasOverflow || overflowBuilder == null) {
      _passAllOverflowWidgets();
      return Size.zero;
    }
    final drawResult = _drawOverflowIndicator(
      objectsOverflowed,
      overflowBuilder,
    );
    _overflowIndicator = drawResult;
    // final overflowIndicatorWidth = drawResult.size.width;
    // if (dx + overflowIndicatorWidth > constraints.maxWidth) {
    //   dx -= lastRenderedChild!.size.width + spacing;
    //   lastRenderedChild?.layout(
    //     ExtendedRenderWrap.shrinkedConstraints,
    //     parentUsesSize: true,
    //   );
    //   final newObjectsOverflowAmount = objectsOverflowed + 1;
    //   final drawResult = _drawOverflowIndicator(
    //     newObjectsOverflowAmount,
    //     overflowBuilder,
    //   );
    //   _overflowIndicator = drawResult;
    // }
    return drawResult.size;
  }

  void _passAllOverflowWidgets() {
    RenderBox? curRenderBox = lastRenderedChild;
    curRenderBox =
        (curRenderBox?.parentData as LimitWrapParentData?)?.nextSibling;
    while (curRenderBox != null) {
      curRenderBox.layout(ExtendedRenderWrap.shrinkedConstraints);
      curRenderBox =
          (curRenderBox.parentData as LimitWrapParentData?)?.nextSibling;
    }
  }

  Size _layoutOverflowChildren(Canvas canvas, int objectsOverflowed) {
    RenderBox? lastChild = lastLayoutedChild;

    Size layoutAndPaintText(
      OverflowBuilderTextItem textBuilder,
      Offset offset,
      Canvas canvas,
    ) {
      final overflowText = textBuilder.textBuilder(objectsOverflowed);
      final overflowTextPainter =
          TextPainter(textDirection: TextDirection.ltr)
            ..text = TextSpan(text: overflowText, style: textBuilder.textStyle)
            ..layout(
              maxWidth:
                  max(0, constraints.maxWidth -
                  (_overflowBuilder?.style.padding.horizontal ?? 0)),
            );
      final textSize = overflowTextPainter.size;
      overflowTextPainter.paint(canvas, offset);
      return textSize;
    }

    Size layoutWidget(OverflowBuilderWidgetItem widget, Offset offset) {
      final parentData = lastChild?.parentData as LimitWrapParentData;
      final curRenderBox = parentData.nextSibling;
      curRenderBox!.layout(constraints, parentUsesSize: true);
      final curParentData = curRenderBox.parentData as LimitWrapParentData;
      curParentData.offset = Offset(dx, dy) + offset;
      lastChild = curRenderBox;
      return curRenderBox.size;
    }

    Size layoutChild(OverflowBuilderItem item, Offset offset, Canvas canvas) =>
        switch (item) {
          OverflowBuilderWidgetItem _ => layoutWidget(item, offset),
          OverflowBuilderTextItem _ => layoutAndPaintText(item, offset, canvas),
        };

    final items = _overflowBuilder?.items;
    if (items == null) return Size.zero;
    var offset = Offset.zero;
    double maxHeight = 0;
    for (final item in items) {
      final childSize = layoutChild(item, offset, canvas);
      maxHeight = max(childSize.height, maxHeight);
      offset += Offset(childSize.width, 0);
    }
    return Size(offset.dx, maxHeight);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent) return;
    final position = event.position;
    final boundary = _gestureTarget;
    if (boundary == null) return;
    if (boundary.contains(position)) {
      _overflowBuilder?.onTap?.call();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final picture = _overflowIndicator?.picture;
    final size = _overflowIndicator?.size;
    if (picture != null) {
      final localDx = dx + offset.dx;
      final localDy = dy + offset.dy;
      _gestureTarget = Rect.fromLTRB(
        localDx,
        localDy,
        localDx + (size?.width ?? 0),
        localDy + (size?.height ?? 0),
      );
      context.canvas.save();
      context.canvas.translate(localDx, localDy);
      context.canvas.drawPicture(picture);
      context.canvas.restore();
    }
  }
}
