import 'package:flutter/painting.dart';

class OverflowBuilderStyle {
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final BoxBorder? border;
  final String Function(int amountOfOverflowedWidgets) textBuilder;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  OverflowBuilderStyle({
    required this.textBuilder,
    this.textStyle,
    this.padding = EdgeInsets.zero,
    this.border,
    this.borderRadius,
    this.color = const Color(0xFF000000),
    this.onTap,
  });
}
