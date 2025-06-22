// ignore_for_file: lines_longer_than_80_chars

part of '../more_than_wrap.dart';

/// ParentData for [_ExtendedRenderWrap]
///
class LimitWrapParentData extends ContainerBoxParentData<RenderBox> {}

/// Custom [RenderBox] for creating [Wrap] with limited number of rows
/// and indicator of overflowed elements
///
class _ExtendedRenderWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, LimitWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, LimitWrapParentData> {
  _ExtendedRenderWrap({
    List<RenderBox>? children,
    required this.runSpacing,
    required this.spacing,
    void Function(int)? onWidgetsLayouted,
    int? maxLines,
    required this.isOverflowWidgetAdded,
  })  : _onWidgetsLayouted = onWidgetsLayouted,
        _maxLines = maxLines {
    addAll(children);
  }

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
  static const _shrinkedConstraints = BoxConstraints(maxWidth: 0, maxHeight: 0);

  /// Spacing between elements in the same row
  final double spacing;

  /// Spacing between rows of elements
  final double runSpacing;

  /// Maximum number of rows
  int? _maxLines;

  /// Function that will be called at the moment when we
  /// learn the number of overflowed elements
  ///
  void Function(int amountOfOverflowedWidgets)? _onWidgetsLayouted;

  /// Flag that shows whether a widget has been added that
  /// needs to be displayed on overflow
  ///
  final bool isOverflowWidgetAdded;

  /// Setter for maximum number of rows
  ///
  /// When updated, the [calculatedOverflow] flag is reset
  /// and redraw is triggered
  ///
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    calculatedOverflow = false;
    markNeedsLayout();
  }

  /// Setter for [onWidgetsLayouted] function
  ///
  /// When updated, the [calculatedOverflow] flag is reset
  /// and redraw is triggered
  ///
  set onWidgetsLayouted(void Function(int amountOfOverflowedWidgets)? fun) {
    _onWidgetsLayouted = fun;
    calculatedOverflow = false;
    markNeedsLayout();
  }

  /// Function that is called when [RenderObject] is updated
  ///
  /// Resets the [calculatedOverflow] flag
  /// and the [isHideLastItemIfOverflowed] flag
  ///
  void onUpdate() {
    isHideLastItemIfOverflowed = false;
    calculatedOverflow = false;
  }

  /// Set parentData for [RenderBox]
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! LimitWrapParentData) {
      child.parentData = LimitWrapParentData();
    }
  }

  /// Main function containing all the logic for building elements
  ///
  /// In it we will draw all children
  ///
  @override
  void performLayout() {
    /// Number of overflowed elements
    int objectsOverflowed = 0;

    /// Total number of children
    var allElements = childCount;

    /// If overflow widget was added, then reduce the counter of all children by 1,
    /// since it won't be counted in the number of widgets to draw
    ///
    if (isOverflowWidgetAdded) allElements -= 1;

    /// Get parent constraints
    final constraints = this.constraints.copyWith(minWidth: 0, minHeight: 0);

    /// Get the first child element
    RenderBox? child = firstChild;

    /// If the first child is immediately null, then we don't
    /// draw anything and specify minimum constraints
    ///
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    /// Offset coordinates for displaying the current element
    double dx = 0;
    double dy = 0;

    /// Maximum height of element for current row
    double maxYPerRow = 0;

    /// Number of rendered rows
    int renderedRows = 1;

    /// Index of current element
    int curIndex = 0;

    /// Initial coordinates of the penultimate rendered
    /// child element
    ///
    Offset? penultimateRenderedChildOffset;

    /// Penultimate rendered child element
    RenderBox? penultimateRenderedChild;

    /// Last rendered child element
    RenderBox? lastRenderedChild;

    /// Flag showing that elements are overflowed
    bool hasOverflow = false;

    /// Function to skip drawing child element
    void passChild() {
      objectsOverflowed++;
      curIndex++;
      child?.layout(
        _shrinkedConstraints,
        parentUsesSize: true,
      );
      final LimitWrapParentData childParentData =
          child?.parentData as LimitWrapParentData;
      child = childParentData.nextSibling;
    }

    /// Loop to iterate through all child elements and draw them
    while (child != null && curIndex < allElements) {
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

    /// Then the following happens:
    ///
    ///             Was overflow widget added for display
    ///                 in case of overflow?
    ///                           |
    ///                           |Yes
    ///                           |
    ///                 Is there overflow?
    ///                        /        \
    ///                 No   /          \ Yes
    ///                      /            \_____ _______
    ///                     /                   |           Do we need to hide the last rendered element?
    ///                    /                    |                        /           \
    ///   Then simply don't draw          |                 No   /             \ Yes
    ///       overflow widget                   |                      /               \
    ///                                         |               nothing to           1. Reduce offset for next element
    ///                                         |                do                on width of last child element and [spacing]
    ///                                         |                                   2. Hide last element with zero constraints
    ///                                         |
    ///                                         |
    ///                                         |________
    ///                                         |              Is overflow calculated yet?
    ///                                         |                      /           \
    ///                                         |            Calculated /             \ Not calculated
    ///                                         |                    /               \
    ///                                         |               nothing to          Schedule microtask (Important: we can't start
    ///                                         |                do                                rebuilding when not fully built [ExtendedRenderWrap]):
    ///                                         |                                      1. Raise flag [calculatedOverflow]
    ///                                         |                                      2. Call [_onWidgetsLayouted]
    ///                                         |                                         passing there number of overflowed elements without considering overflow widget
    ///                                         |                                      2. Reset number of overflowed elements
    ///                                         |
    ///                                         |
    ///                                         |
    ///                                         |
    ///                              Draw overflow widget
    ///                                         |
    ///                                         |
    ///                                         |
    ///                                         |_____________
    ///                                         |                 Is overflow widget removed (OR) only widget for searching hash tags not removed?
    ///                                         |                     (this check only happens when flag
    ///                                         |                    that count of not removed elements [calculatedOverflow] is raised)
    ///                                         |                                      /           \
    ///                                         |                               No   /             \
    ///                                         |                                    /               \
    ///                                         |                                nothing to         1. Raise flag [isHideLastItemIfOverflowed] so that
    ///                                         |                                                     not draw last element
    ///                                         |                                 do           2. Increase number of not removed elements by 1
    ///                                         |                                                  3. Schedule microtask:
    ///                                         |                                                     - 1. Call [_onWidgetsLayouted] passing
    ///                                         |                                                         there number of overflowed elements without considering overflow widget
    ///                                         |                                                     - 2. Reset number of overflowed elements
    ///                                         |
    ///                                         |
    ///                                         |
    ///                                         |
    ///                  Mark constraints for all parent [RenderBox]
    ///
    if (isOverflowWidgetAdded) {
      final overflowRender = lastChild;
      if (!hasOverflow) {
        overflowRender?.layout(
          _shrinkedConstraints,
          parentUsesSize: true,
        );
      } else {
        if (isHideLastItemIfOverflowed) {
          dx -= lastRenderedChild!.size.width + spacing;

          /// Case when dx == 0 is possible if child on last row occupied all width,
          /// in such case move overflow widget to previous row and shift right
          /// on width of widget from previous row
          if (dx == 0 &&
              penultimateRenderedChildOffset != null &&
              penultimateRenderedChild != null) {
            overflowRender?.layout(constraints, parentUsesSize: true);
            final size = overflowRender!.size;

            final potentialXOverflowWidgetEndOffset =
                penultimateRenderedChildOffset.dx +
                    penultimateRenderedChild.size.width +
                    spacing +
                    size.width;

            /// If overflow widget does not go beyond border, then shift it
            if (potentialXOverflowWidgetEndOffset <= constraints.maxWidth) {
              dx += penultimateRenderedChildOffset.dx +
                  penultimateRenderedChild.size.width +
                  spacing;
              dy -= penultimateRenderedChild.size.height + runSpacing;
            }
          }
          lastRenderedChild.layout(
            _shrinkedConstraints,
            parentUsesSize: true,
          );
        }
        if (!calculatedOverflow) {
          Future.microtask(() {
            calculatedOverflow = true;
            _onWidgetsLayouted?.call(objectsOverflowed);
            objectsOverflowed = 0;
          });
        }

        overflowRender?.layout(constraints, parentUsesSize: true);
        final childParentData =
            overflowRender?.parentData as LimitWrapParentData?;
        childParentData?.offset = Offset(dx, dy);

        /// More reliable condition, but answers less requirements
        /// In case of critical bugs return its use
        ///
        ///if(childParentData!.offset.dx + overflowRender!.size.width > constraints.maxWidth && calculatedOverflow)
        final endOverflowRenderXOffset =
            childParentData!.offset.dx + overflowRender!.size.width;
        if ((endOverflowRenderXOffset > constraints.maxWidth ||
                objectsOverflowed == 1) &&
            calculatedOverflow) {
          isHideLastItemIfOverflowed = true;
          objectsOverflowed++;
          Future.microtask(() {
            _onWidgetsLayouted?.call(objectsOverflowed);
            objectsOverflowed = 0;
          });
        }
      }
    }
    size = constraints.constrain(Size(constraints.maxWidth, dy + maxYPerRow));
  }

  /// Add [RenderBox]'s ability to handle taps
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  /// Draw result
  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
