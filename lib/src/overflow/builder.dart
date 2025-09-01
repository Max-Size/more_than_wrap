import 'package:flutter/foundation.dart';
import 'package:more_than_wrap/src/overflow/item.dart';
import 'package:more_than_wrap/src/overflow/style.dart';

class OverflowBuilder {
  final List<OverflowBuilderItem> items;

  final OverflowBuilderStyle style;

  final VoidCallback? onTap;

  OverflowBuilder({
    required this.items,
    this.style = const OverflowBuilderStyle(),
    this.onTap,
  });
}
