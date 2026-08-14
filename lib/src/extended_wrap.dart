import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/count_builder.dart';

/// Parent data for [RenderExtendedWrap] children.
class ExtendedWrapParentData extends ContainerBoxParentData<RenderBox> {}

/// Multi-child wrap that keeps at most [maxLines] rows.
///
/// The last child must be an [OverflowCountBuilder] slot. Remaining children
/// are the wrap items; overflowed items are laid out with zero constraints.
class ExtendedWrap extends MultiChildRenderObjectWidget {
  const ExtendedWrap({
    super.key,
    required super.children,
    this.maxLines,
    this.spacing = 0,
    this.runSpacing = 0,
  });

  /// Maximum number of rows. `null` means unlimited.
  final int? maxLines;

  /// Horizontal gap between items in a row.
  final double spacing;

  /// Vertical gap between rows.
  final double runSpacing;

  @override
  RenderExtendedWrap createRenderObject(BuildContext context) {
    return RenderExtendedWrap(
      maxLines: maxLines,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderExtendedWrap renderObject,
  ) {
    renderObject
      ..maxLines = maxLines
      ..spacing = spacing
      ..runSpacing = runSpacing;
  }
}

/// Lays out wrap children with a max row count and an overflow slot.
///
/// Last child is expected to be [RenderOverflowCountBuilder]. During layout the
/// overflow count is injected into that slot (LayoutBuilder-style) so the
/// indicator is built in the same frame.
class RenderExtendedWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ExtendedWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ExtendedWrapParentData> {
  RenderExtendedWrap({
    int? maxLines,
    required double spacing,
    required double runSpacing,
  }) : _maxLines = maxLines,
       _spacing = spacing,
       _runSpacing = runSpacing;

  static const _shrinkedConstraints = BoxConstraints(
    maxWidth: 0,
    maxHeight: 0,
  );

  int? _maxLines;
  double _spacing;
  double _runSpacing;

  int? get maxLines => _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) {
      return;
    }
    _maxLines = value;
    markNeedsLayout();
  }

  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) {
      return;
    }
    _spacing = value;
    markNeedsLayout();
  }

  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) {
      return;
    }
    _runSpacing = value;
    markNeedsLayout();
  }

  int _objectsOverflowed = 0;
  double _dx = 0;
  double _dy = 0;
  double _maxYPerRow = 0;
  RenderBox? _lastRenderedChild;
  RenderBox? _penultimateRenderedChild;
  Offset? _penultimateRenderedChildOffset;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ExtendedWrapParentData) {
      child.parentData = ExtendedWrapParentData();
    }
  }

  @override
  BoxConstraints get constraints =>
      super.constraints.copyWith(minWidth: 0, minHeight: 0);

  @override
  void performLayout() {
    _objectsOverflowed = 0;
    _dx = 0;
    _dy = 0;
    _maxYPerRow = 0;
    _lastRenderedChild = null;
    _penultimateRenderedChild = null;
    _penultimateRenderedChildOffset = null;

    // Last child is the overflow slot.
    final itemCount = max(0, childCount - 1);
    RenderBox? child = firstChild;

    if (child == null) {
      size = constraints.smallest;
      return;
    }

    var renderedRows = 1;
    var curIndex = 0;
    var hasOverflow = false;

    void passChild() {
      _objectsOverflowed++;
      curIndex++;
      child!.layout(_shrinkedConstraints, parentUsesSize: true);
      final parentData = child!.parentData! as ExtendedWrapParentData;
      child = parentData.nextSibling;
    }

    while (child != null && curIndex < itemCount) {
      if (hasOverflow) {
        passChild();
        continue;
      }

      child!.layout(constraints, parentUsesSize: true);
      final childSize = child!.size;

      if (_maxLines != null) {
        final wouldExceedLastRow =
            renderedRows == _maxLines &&
            _dx + childSize.width + _spacing > constraints.maxWidth;
        if (renderedRows > _maxLines! || wouldExceedLastRow) {
          hasOverflow = true;
          passChild();
          continue;
        }
      }

      if (_dx + childSize.width + _spacing > constraints.maxWidth) {
        renderedRows++;
        _dx = 0;
        _dy += _maxYPerRow + _runSpacing;
        _maxYPerRow = 0;
      }

      final parentData = child!.parentData! as ExtendedWrapParentData;
      parentData.offset = Offset(_dx, _dy);

      curIndex++;
      _dx += childSize.width + _spacing;

      _penultimateRenderedChild = _lastRenderedChild;
      _penultimateRenderedChildOffset =
          (_lastRenderedChild?.parentData as ExtendedWrapParentData?)?.offset;
      _lastRenderedChild = child;
      _maxYPerRow = max(_maxYPerRow, childSize.height);

      child = parentData.nextSibling;
    }

    _layoutOverflowSlot(hasOverflow);

    final height = max(_dy + _maxYPerRow, constraints.minHeight);
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  void _layoutOverflowSlot(bool hasOverflow) {
    final overflowRender = lastChild;
    if (overflowRender == null) {
      return;
    }

    if (!hasOverflow) {
      _setOverflowCount(overflowRender, 0);
      overflowRender.layout(_shrinkedConstraints, parentUsesSize: true);
      return;
    }

    _layoutOverflowChild(overflowRender, _objectsOverflowed);

    final endX = _dx + overflowRender.size.width;
    final needsRoom = endX > constraints.maxWidth || _objectsOverflowed == 1;

    if (needsRoom) {
      _hideLastVisibleChild(overflowRender);
      _layoutOverflowChild(overflowRender, _objectsOverflowed);
    }
  }

  void _setOverflowCount(RenderBox overflowRender, int count) {
    if (overflowRender is! RenderOverflowCountBuilder) {
      return;
    }
    final slot = overflowRender;
    if (slot.overflowCount == count) {
      return;
    }
    // Mutating a descendant's layout flags is only allowed inside
    // [invokeLayoutCallback] (same mechanism LayoutBuilder uses).
    invokeLayoutCallback<BoxConstraints>((_) {
      slot.overflowCount = count;
      // Force another [performLayout] when constraints did not change.
      slot.markNeedsLayout();
    });
  }

  void _layoutOverflowChild(RenderBox overflowRender, int count) {
    _setOverflowCount(overflowRender, count);
    overflowRender.layout(constraints, parentUsesSize: true);
    final parentData = overflowRender.parentData! as ExtendedWrapParentData;
    parentData.offset = Offset(_dx, _dy);
  }

  void _hideLastVisibleChild(RenderBox overflowRender) {
    final last = _lastRenderedChild;
    if (last == null) {
      return;
    }

    _dx -= last.size.width + _spacing;

    // If that child alone filled the last row, try previous row.
    if (_dx == 0 &&
        _penultimateRenderedChildOffset != null &&
        _penultimateRenderedChild != null) {
      overflowRender.layout(constraints, parentUsesSize: true);
      final overflowSize = overflowRender.size;
      final potentialEnd =
          _penultimateRenderedChildOffset!.dx +
          _penultimateRenderedChild!.size.width +
          _spacing +
          overflowSize.width;

      if (potentialEnd <= constraints.maxWidth) {
        _dx =
            _penultimateRenderedChildOffset!.dx +
            _penultimateRenderedChild!.size.width +
            _spacing;
        _dy -= _penultimateRenderedChild!.size.height + _runSpacing;
      }
    }

    last.layout(_shrinkedConstraints, parentUsesSize: true);
    _objectsOverflowed++;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as ExtendedWrapParentData;
      context.paintChild(child, parentData.offset + offset);
      child = parentData.nextSibling;
    }
  }
}
