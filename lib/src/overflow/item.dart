import 'package:flutter/widgets.dart';

sealed class OverflowBuilderItem {
  const OverflowBuilderItem();

  factory OverflowBuilderItem.widget({required Widget child}) =
      OverflowBuilderWidgetItem;

  factory OverflowBuilderItem.text({
    required String Function(int amountOfOverflowedWidgets) textBuilder,
    required final TextStyle? textStyle,
  }) = OverflowBuilderTextItem;
}

class OverflowBuilderWidgetItem extends OverflowBuilderItem {
  final Widget child;

  const OverflowBuilderWidgetItem({required this.child});
}

class OverflowBuilderTextItem extends OverflowBuilderItem {
  final String Function(int amountOfOverflowedWidgets) textBuilder;
  final TextStyle? textStyle;

  const OverflowBuilderTextItem({
    required this.textBuilder,
    required this.textStyle,
  });
}
