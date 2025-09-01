import 'package:flutter/widgets.dart';

class OverflowBuilderStyle {
  final EdgeInsets padding;
  final BoxBorder? border;
  final Radius? radius;
  final Color? color;

  const OverflowBuilderStyle({
    this.padding = EdgeInsets.zero,
    this.border,
    this.radius,
    this.color,
  });
}
