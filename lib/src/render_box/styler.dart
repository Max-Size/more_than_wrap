import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow_style.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';

class _DrawResult {
  final Picture picture;
  final Size size;

  _DrawResult({required this.picture, required this.size});
}

class ExtendedRenderWrapWidgetStyler extends ExtendedRenderWrap<String> {
  OverflowBuilderStyle? _overflowBuilderStyle;
  _DrawResult? _overflowIndicator;
  Rect? _gestureTarget;

  ExtendedRenderWrapWidgetStyler({
    required OverflowBuilderStyle? overflowBuilderStyle,
    required super.runSpacing,
    required super.spacing,
    super.children,
    super.onWidgetsLayouted,
    super.maxLines,
  }) : _overflowBuilderStyle = overflowBuilderStyle,
       super(isOverflowWidgetAdded: false);

  set overflowBuilderStyle(OverflowBuilderStyle? overflowBuilderStyle) {
    _overflowBuilderStyle = overflowBuilderStyle;
    markNeedsLayout();
  }

  _DrawResult _drawOverflowIndicator(
    int objectsOverflowed,
    OverflowBuilderStyle overflowBuilder,
  ) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final overflowText = overflowBuilder.textBuilder(objectsOverflowed);
    final paddingHorizontal = overflowBuilder.padding.horizontal;
    final overflowTextPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(text: overflowText, style: overflowBuilder.textStyle)
      ..layout(maxWidth: constraints.maxWidth - paddingHorizontal);
    final textSize = overflowTextPainter.size;
    final overflowWidth = textSize.width + paddingHorizontal;
    final overflowHeight = textSize.height + overflowBuilder.padding.vertical;
    final radius = overflowBuilder.radius ?? Radius.zero;
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
            overflowBuilder.color ?? const Color.fromARGB(255, 145, 128, 128),
    );
    final border = overflowBuilder.border;
    if (border != null) {
      border.paint(
        canvas,
        overflowRect.outerRect,
        textDirection: TextDirection.ltr,
        borderRadius: BorderRadius.all(radius),
      );
    }
    overflowTextPainter.paint(
      canvas,
      Offset(overflowBuilder.padding.left, overflowBuilder.padding.top),
    );
    final size = Size(overflowWidth, overflowHeight);
    final picture = recorder.endRecording();
    return _DrawResult(picture: picture, size: size);
  }

  @override
  void layoutOverflowIndicator(bool hasOverflow) {
    if (!hasOverflow) {
      _overflowIndicator = null;
    }
    final overflowBuilder = _overflowBuilderStyle;
    if (!hasOverflow || overflowBuilder == null) {
      return;
    }
    final drawResult = _drawOverflowIndicator(
      objectsOverflowed,
      overflowBuilder,
    );
    _overflowIndicator = drawResult;
    final overflowIndicatorWidth = drawResult.size.width;
    if (dx + overflowIndicatorWidth > constraints.maxWidth) {
      dx -= lastRenderedChild!.size.width + spacing;
      lastRenderedChild?.layout(
        ExtendedRenderWrap.shrinkedConstraints,
        parentUsesSize: true,
      );
      final drawResult = _drawOverflowIndicator(
        objectsOverflowed + 1,
        overflowBuilder,
      );
      _overflowIndicator = drawResult;
    }
    // picture.
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
      _overflowBuilderStyle?.onTap?.call();
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
