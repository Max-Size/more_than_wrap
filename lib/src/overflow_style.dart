import 'package:flutter/painting.dart';

class OverflowBuilderStyle {
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final BoxBorder? border;
  final String Function(int amountOfOverflowedWidgets) textBuilder;
  final Radius? radius;
  final Color? color;
  final VoidCallback? onTap;

  OverflowBuilderStyle({
    required this.textBuilder,
    this.textStyle,
    this.padding = EdgeInsets.zero,
    this.border,
    this.radius,
    this.color = const Color(0xFF000000),
    this.onTap,
  });
}
