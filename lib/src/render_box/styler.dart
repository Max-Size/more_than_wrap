import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/overflow_style.dart';
import 'package:more_than_wrap/src/render_box/render_box.dart';

class ExtendedRenderWrapWidgetStyler extends ExtendedRenderWrap<String> {
  OverflowBuilderStyle? _overflowBuilderStyle;
  Picture? _overflowIndicatorPicture;

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

  @override
  void layoutOverflowIndicator(bool hasOverflow) {
    if (!hasOverflow) {
      _overflowIndicatorPicture = null;
    }
    final overflowBuilder = _overflowBuilderStyle;
    if (!hasOverflow || overflowBuilder == null) {
      return;
    }
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
    _overflowIndicatorPicture = recorder.endRecording();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (_overflowIndicatorPicture != null) {
      context.canvas.save();
      context.canvas.translate(dx + offset.dx, dy + offset.dy);
      context.canvas.drawPicture(_overflowIndicatorPicture!);
      context.canvas.restore();
    }
  }
}
