import 'dart:math';

import 'package:flutter/rendering.dart';

/// ParentData for [_ExtendedRenderWrap]
///
class LimitWrapParentData extends ContainerBoxParentData<RenderBox> {}

/// Custom [RenderBox] for creating [Wrap] with limited number of rows
/// and indicator of overflowed elements
///
abstract class ExtendedRenderWrap<T> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, LimitWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, LimitWrapParentData> {
  ExtendedRenderWrap({
    List<RenderBox>? children,
    required this.runSpacing,
    required this.spacing,
    T Function(int)? onWidgetsLayouted,
    int? maxLines,
    required this.isOverflowWidgetAdded,
    required int amountOfActualWrapChildren,
  }) : _amountOfActualWrapChildren = amountOfActualWrapChildren,
       onWidgetsLayoutedInternal = onWidgetsLayouted,
       _maxLines = maxLines {
    addAll(children);
  }

  int _amountOfActualWrapChildren;

  /// Flag - whether the number of overflowed elements has been calculated
  bool calculatedOverflow = false;

  /// Flag - whether to hide the last element that was able to fit
  ///
  /// In case of bugs, it will be necessary to replace with count
  ///
  bool isHideLastItemIfOverflowed = false;

  /// Zero constraints for those [RenderBox]'s that we won't
  /// display on screen
  ///
  static const shrinkedConstraints = BoxConstraints(maxWidth: 0, maxHeight: 0);

  /// Spacing between elements in the same row
  final double spacing;

  /// Spacing between rows of elements
  final double runSpacing;

  /// Maximum number of rows
  int? _maxLines;

  /// Function that will be called at the moment when we
  /// learn the number of overflowed elements
  ///
  void Function(int amountOfOverflowedWidgets)? onWidgetsLayoutedInternal;

  /// Flag that shows whether a widget has been added that
  /// needs to be displayed on overflow
  ///
  final bool isOverflowWidgetAdded;

  set amountOfActualWrapChildren(int amount) {
    _amountOfActualWrapChildren = amount;
  }

  /// Setter for maximum number of rows
  ///
  /// When updated, the [calculatedOverflow] flag is reset
  /// and redraw is triggered
  ///
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    // calculatedOverflow = false;
    markNeedsLayout();
  }

  /// Setter for [onWidgetsLayoutedInternal] function
  ///
  /// When updated, the [calculatedOverflow] flag is reset
  /// and redraw is triggered
  ///
  set onWidgetsLayouted(void Function(int amountOfOverflowedWidgets)? fun) {
    onWidgetsLayoutedInternal = fun;
    // calculatedOverflow = false;
    markNeedsLayout();
  }

  /// Function that is called when [RenderObject] is updated
  ///
  /// Resets the [calculatedOverflow] flag
  /// and the [isHideLastItemIfOverflowed] flag
  ///
  void onUpdate() {
    isHideLastItemIfOverflowed = false;
    markNeedsLayout();
    hasOverflow = false;
    visibleRenderBoxes.clear();
    // calculatedOverflow = false;
  }

  /// Set parentData for [RenderBox]
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! LimitWrapParentData) {
      child.parentData = LimitWrapParentData();
    }
  }

  /// Number of overflowed elements
  int objectsOverflowed = 0;

  /// Initial coordinates of the penultimate rendered
  /// child element
  ///
  Offset? penultimateRenderedChildOffset;

  /// Penultimate rendered child element
  RenderBox? penultimateRenderedChild;

  /// Offset coordinates for displaying the current element
  double dx = 0;
  double dy = 0;

  /// Last rendered child element
  RenderBox? lastRenderedChild;

  RenderBox? lastLayoutedChild;

  var visibleRenderBoxes = <int, List<RenderBox?>>{};

  @override
  BoxConstraints get constraints =>
      super.constraints.copyWith(minWidth: 0, minHeight: 0);

  /// Flag showing that elements are overflowed
  bool hasOverflow = false;

  /// Main function containing all the logic for building elements
  ///
  /// In it we will draw all children
  ///
  @override
  void performLayout() {
    objectsOverflowed = 0;
    dx = 0;
    dy = 0;

    /// Total number of children
    var allElements = childCount;

    /// If overflow widget was added, then reduce the counter of all children by 1,
    /// since it won't be counted in the number of widgets to draw
    ///
    if (isOverflowWidgetAdded) allElements -= 1;

    /// Get the first child element
    RenderBox? child = firstChild;

    /// If the first child is immediately null, then we don't
    /// draw anything and specify minimum constraints
    ///
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    /// Maximum height of element for current row
    double maxYPerRow = 0;

    /// Number of rendered rows
    int renderedRows = 1;

    /// Index of current element
    int curIndex = 0;

    /// Function to skip drawing child element
    void passChild() {
      objectsOverflowed++;
      curIndex++;
      child?.layout(shrinkedConstraints, parentUsesSize: true);
      final LimitWrapParentData childParentData =
          child?.parentData as LimitWrapParentData;
      child = childParentData.nextSibling;
    }

    /// Loop to iterate through all child elements and draw them
    while (child != null && curIndex < allElements) {
      if (curIndex > _amountOfActualWrapChildren - 1) break;
      lastLayoutedChild = child;

      /// If already overflowed, then skip child element
      if (hasOverflow) {
        passChild();
        continue;
      }

      /// Layout child element and get its dimensions
      child!.layout(constraints, parentUsesSize: true);
      final childSize = child!.size;

      /// If maximum number of rows constraint was passed,
      /// then before going further we check if there's enough space for it
      ///
      /// If there's already not enough space, then raise the flag that
      /// overflow occurred and skip child element
      ///
      if (_maxLines != null) {
        if (renderedRows > _maxLines! ||
            renderedRows == _maxLines! &&
                dx + childSize.width + spacing > constraints.maxWidth) {
          hasOverflow = true;
          passChild();
          continue;
        }
      }

      /// If element for drawing is not removed from this row, then
      /// move it to the next and increase the row counter
      if (dx + childSize.width + spacing > constraints.maxWidth) {
        renderedRows++;
        dx = 0;
        dy += maxYPerRow + runSpacing;
        maxYPerRow = 0;
      }

      visibleRenderBoxes[renderedRows] ??= [];
      visibleRenderBoxes[renderedRows]!.add(child);

      /// Set offset for current child element
      final LimitWrapParentData childParentData =
          child!.parentData as LimitWrapParentData;
      childParentData.offset = Offset(dx, dy);

      /// Increase offset for next child element and index
      curIndex++;
      dx += childSize.width + spacing;

      /// Update last and penultimate rendered child element
      /// and maximum value of height for current row
      penultimateRenderedChild = lastRenderedChild;
      penultimateRenderedChildOffset =
          (lastRenderedChild?.parentData as LimitWrapParentData?)?.offset;
      lastRenderedChild = child;
      maxYPerRow = max(maxYPerRow, childSize.height);

      /// Look at next child
      child = childParentData.nextSibling;
    }

    final overflowIndicatorSize = layoutOverflowIndicator(hasOverflow);
    final overflowIndicatorWidth = overflowIndicatorSize.width;
    if (dx + overflowIndicatorWidth > constraints.maxWidth) {
      final amountOfHidedElements = _hideRenderedBoxes(overflowIndicatorWidth);
      objectsOverflowed += amountOfHidedElements;
      layoutOverflowIndicator(hasOverflow);
    }

    final height = max(dy + maxYPerRow, this.constraints.minHeight);
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  int _hideRenderedBoxes(double overflowIndicatorWidth) {
    int amount = 0;
    final lastRow = visibleRenderBoxes.keys.last;
    for (final renderedBox in visibleRenderBoxes[lastRow]!.reversed) {
      if (renderedBox != null && renderedBox.size.width > 0) {
        if (dx + overflowIndicatorWidth > constraints.maxWidth) {
          amount++;
          dx -= renderedBox.size.width + spacing;
          renderedBox.layout(shrinkedConstraints, parentUsesSize: true);
        } else {
          break;
        }
      }
    }
    return amount;
  }

  Size layoutOverflowIndicator(bool hasOverflow);

  /// Add [RenderBox]'s ability to handle taps
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  /// Draw result
  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    int index = 0;
    while (child != null) {
      if (!hasOverflow && index > _amountOfActualWrapChildren - 1) break;
      final LimitWrapParentData childParentData =
          child.parentData! as LimitWrapParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
      index++;
    }
  }
}
