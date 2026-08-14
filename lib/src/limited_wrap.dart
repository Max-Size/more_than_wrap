import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:more_than_wrap/src/count_builder.dart';

/// Parent data for [RenderLimitedWrap] children.
class LimitedWrapParentData extends ContainerBoxParentData<RenderBox> {
  /// Index of the wrap item, or `null` for the overflow slot.
  int? index;

  /// Whether this child is the overflow indicator rather than a wrap item.
  bool isOverflow = false;
}

/// Creates and disposes wrap children during layout, like a sliver child
/// manager. Implemented by [LimitedWrapElement].
abstract class LimitedWrapChildManager {
  /// Number of wrap items in the widget configuration (not all are mounted).
  int get itemCount;

  /// Inflates the item at [index] and inserts it after [after] (`null` = first).
  void createItem(int index, {required RenderBox? after});

  /// Unmounts the element for [child]. Items must be removed from the end.
  void removeItem(RenderBox child);

  /// Inflates the overflow slot after [after] (`null` = only child).
  void createOverflowSlot({required RenderBox? after});

  /// Unmounts the overflow slot if it is mounted.
  void removeOverflowSlot();
}

const _OverflowSlot _overflowSlot = _OverflowSlot();

class _OverflowSlot {
  const _OverflowSlot();
}

abstract class _LimitedWrapChildDelegate {
  const _LimitedWrapChildDelegate();

  int get itemCount;

  Widget build(BuildContext context, int index);
}

class _LimitedWrapListDelegate extends _LimitedWrapChildDelegate {
  const _LimitedWrapListDelegate(this.children);

  final List<Widget> children;

  @override
  int get itemCount => children.length;

  @override
  Widget build(BuildContext context, int index) => children[index];
}

class _LimitedWrapBuilderDelegate extends _LimitedWrapChildDelegate {
  const _LimitedWrapBuilderDelegate({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  final int itemCount;

  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context, int index) => itemBuilder(context, index);
}

/// Multi-child wrap that keeps at most [maxLines] rows.
///
/// Children are inflated lazily during layout: only items that fit (plus the
/// overflow slot when needed) are mounted. Overflowed items are never left in
/// the tree.
///
/// The default constructor takes a [children] list (widgets are created
/// eagerly, elements are not). [LimitedWrap.builder] defers widget creation
/// until an item is about to be laid out.
///
/// Layout is always horizontal, like [Wrap] with `direction: Axis.horizontal`.
class LimitedWrap extends RenderObjectWidget {
  /// Creates a wrap from an existing [children] list.
  ///
  /// All widgets in [children] are instantiated up front; only those that fit
  /// are mounted into the tree.
  LimitedWrap({
    super.key,
    required List<Widget> children,
    required this.overflowWidgetBuilder,
    this.maxLines,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  }) : _delegate = _LimitedWrapListDelegate(children);

  /// Creates a wrap that builds children on demand.
  ///
  /// [itemBuilder] is invoked only for indices that need to be measured or
  /// shown. Children beyond the visible prefix are never built.
  LimitedWrap.builder({
    super.key,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required this.overflowWidgetBuilder,
    this.maxLines,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  }) : assert(itemCount >= 0),
       _delegate = _LimitedWrapBuilderDelegate(
         itemCount: itemCount,
         itemBuilder: itemBuilder,
       );

  final _LimitedWrapChildDelegate _delegate;

  /// Builds the overflow indicator from the hidden-child count.
  final LimitedWrapOverflowBuilder overflowWidgetBuilder;

  /// Maximum number of rows. `null` means unlimited.
  final int? maxLines;

  /// How much space to place between children in a run in the main axis.
  final double spacing;

  /// How much space to place between the runs themselves in the cross axis.
  final double runSpacing;

  /// How the children within a run should be placed in the main axis.
  final WrapAlignment alignment;

  /// How the runs themselves should be placed in the cross axis.
  final WrapAlignment runAlignment;

  /// How the children within a run should be aligned in the cross axis.
  final WrapCrossAlignment crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// Determines the order to lay runs out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  final VerticalDirection verticalDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  @override
  RenderObjectElement createElement() => LimitedWrapElement(this);

  @override
  RenderLimitedWrap createRenderObject(BuildContext context) {
    return RenderLimitedWrap(
      childManager: context as LimitedWrapChildManager,
      maxLines: maxLines,
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      verticalDirection: verticalDirection,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderLimitedWrap renderObject,
  ) {
    renderObject
      ..maxLines = maxLines
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..alignment = alignment
      ..runAlignment = runAlignment
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..verticalDirection = verticalDirection
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    properties.add(DoubleProperty('spacing', spacing, defaultValue: 0.0));
    properties.add(DoubleProperty('runSpacing', runSpacing, defaultValue: 0.0));
    properties.add(EnumProperty<WrapAlignment>('alignment', alignment));
    properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment));
    properties.add(
      EnumProperty<WrapCrossAlignment>(
        'crossAxisAlignment',
        crossAxisAlignment,
      ),
    );
    properties.add(
      EnumProperty<TextDirection>(
        'textDirection',
        textDirection,
        defaultValue: null,
      ),
    );
    properties.add(
      EnumProperty<VerticalDirection>(
        'verticalDirection',
        verticalDirection,
        defaultValue: VerticalDirection.down,
      ),
    );
    properties.add(
      EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.none),
    );
  }
}

/// Inflates wrap items and the overflow slot on demand during layout.
class LimitedWrapElement extends RenderObjectElement
    implements LimitedWrapChildManager {
  LimitedWrapElement(LimitedWrap super.widget);

  @override
  LimitedWrap get widget => super.widget as LimitedWrap;

  @override
  RenderLimitedWrap get renderObject => super.renderObject as RenderLimitedWrap;

  final List<Element> _items = [];
  Element? _overflowElement;
  RenderBox? _currentBeforeChild;
  Object? _currentlyUpdatingSlot;

  @override
  int get itemCount => widget._delegate.itemCount;

  Widget _itemAt(int index) => widget._delegate.build(this, index);

  @override
  void update(covariant LimitedWrap newWidget) {
    super.update(newWidget);
    _updateChildren();
    renderObject.markNeedsLayout();
  }

  @override
  void performRebuild() {
    super.performRebuild();
    _updateChildren();
  }

  void _updateChildren() {
    while (_items.length > widget._delegate.itemCount) {
      final index = _items.length - 1;
      _currentlyUpdatingSlot = index;
      try {
        updateChild(_items.removeLast(), null, index);
      } finally {
        _currentlyUpdatingSlot = null;
      }
    }

    RenderBox? before;
    for (var i = 0; i < _items.length; i++) {
      _currentBeforeChild = before;
      _currentlyUpdatingSlot = i;
      try {
        final updated = updateChild(_items[i], _itemAt(i), i)!;
        _items[i] = updated;
        before = updated.renderObject as RenderBox?;
      } finally {
        _currentlyUpdatingSlot = null;
      }
    }

    if (_overflowElement != null) {
      _currentBeforeChild = before;
      _currentlyUpdatingSlot = _overflowSlot;
      try {
        _overflowElement = updateChild(
          _overflowElement,
          OverflowCountBuilder(builder: widget.overflowWidgetBuilder),
          _overflowSlot,
        );
      } finally {
        _currentlyUpdatingSlot = null;
      }
    }
  }

  @override
  void createItem(int index, {required RenderBox? after}) {
    assert(index >= 0 && index < widget._delegate.itemCount);
    assert(
      index == _items.length,
      'Items must be created in order from the end.',
    );
    owner!.buildScope(this, () {
      _currentBeforeChild = after;
      _currentlyUpdatingSlot = index;
      try {
        final newChild = updateChild(null, _itemAt(index), index);
        if (newChild != null) {
          _items.add(newChild);
        }
      } finally {
        _currentlyUpdatingSlot = null;
      }
    });
  }

  @override
  void removeItem(RenderBox child) {
    final index = (child.parentData! as LimitedWrapParentData).index!;
    assert(index == _items.length - 1, 'Items must be removed from the end.');
    owner!.buildScope(this, () {
      _currentlyUpdatingSlot = index;
      try {
        final result = updateChild(_items[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingSlot = null;
      }
      _items.removeLast();
    });
  }

  @override
  void createOverflowSlot({required RenderBox? after}) {
    if (_overflowElement != null) {
      return;
    }
    owner!.buildScope(this, () {
      _currentBeforeChild = after;
      _currentlyUpdatingSlot = _overflowSlot;
      try {
        _overflowElement = updateChild(
          null,
          OverflowCountBuilder(builder: widget.overflowWidgetBuilder),
          _overflowSlot,
        );
      } finally {
        _currentlyUpdatingSlot = null;
      }
    });
  }

  @override
  void removeOverflowSlot() {
    if (_overflowElement == null) {
      return;
    }
    owner!.buildScope(this, () {
      _currentlyUpdatingSlot = _overflowSlot;
      try {
        final result = updateChild(_overflowElement, null, _overflowSlot);
        assert(result == null);
      } finally {
        _currentlyUpdatingSlot = null;
      }
      _overflowElement = null;
    });
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    assert(slot == _currentlyUpdatingSlot);
    final renderChild = child as RenderBox;
    renderObject.insert(renderChild, after: _currentBeforeChild);
    _applySlot(renderChild, slot);
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object? oldSlot,
    Object? newSlot,
  ) {
    assert(newSlot == _currentlyUpdatingSlot);
    final renderChild = child as RenderBox;
    renderObject.move(renderChild, after: _currentBeforeChild);
    _applySlot(renderChild, newSlot);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    assert(child.parent == renderObject);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in List<Element>.of(_items)) {
      visitor(child);
    }
    final overflow = _overflowElement;
    if (overflow != null) {
      visitor(overflow);
    }
  }

  @override
  void forgetChild(Element child) {
    if (child.slot == _overflowSlot) {
      _overflowElement = null;
    } else {
      _items.remove(child);
    }
    super.forgetChild(child);
  }

  void _applySlot(RenderBox child, Object? slot) {
    final parentData = child.parentData! as LimitedWrapParentData;
    if (slot is int) {
      parentData.index = slot;
      parentData.isOverflow = false;
    } else {
      parentData.index = null;
      parentData.isOverflow = true;
    }
  }
}

class _Run {
  final List<RenderBox> children = [];
  double mainAxisExtent = 0;
  double crossAxisExtent = 0;

  void add(RenderBox child, double spacing) {
    if (children.isNotEmpty) {
      mainAxisExtent += spacing;
    }
    children.add(child);
    mainAxisExtent += child.size.width;
    crossAxisExtent = max(crossAxisExtent, child.size.height);
  }

  RenderBox removeLast(double spacing) {
    final child = children.removeLast();
    mainAxisExtent -= child.size.width;
    if (children.isNotEmpty) {
      mainAxisExtent -= spacing;
    }
    crossAxisExtent = 0;
    for (final remaining in children) {
      crossAxisExtent = max(crossAxisExtent, remaining.size.height);
    }
    return child;
  }
}

(double, double) _distributeSpace(
  WrapAlignment alignment,
  double freeSpace,
  double itemSpacing,
  int itemCount,
  bool flipped,
) {
  assert(itemCount > 0);
  return switch (alignment) {
    WrapAlignment.start => (flipped ? freeSpace : 0.0, itemSpacing),
    WrapAlignment.end => _distributeSpace(
      WrapAlignment.start,
      freeSpace,
      itemSpacing,
      itemCount,
      !flipped,
    ),
    WrapAlignment.spaceBetween when itemCount < 2 => _distributeSpace(
      WrapAlignment.start,
      freeSpace,
      itemSpacing,
      itemCount,
      flipped,
    ),
    WrapAlignment.center => (freeSpace / 2.0, itemSpacing),
    WrapAlignment.spaceBetween => (
      0,
      freeSpace / (itemCount - 1) + itemSpacing,
    ),
    WrapAlignment.spaceAround => (
      freeSpace / itemCount / 2,
      freeSpace / itemCount + itemSpacing,
    ),
    WrapAlignment.spaceEvenly => (
      freeSpace / (itemCount + 1),
      freeSpace / (itemCount + 1) + itemSpacing,
    ),
  };
}

double _crossAlignmentFactor(WrapCrossAlignment alignment) {
  return switch (alignment) {
    WrapCrossAlignment.start => 0,
    WrapCrossAlignment.end => 1,
    WrapCrossAlignment.center => 0.5,
  };
}

WrapCrossAlignment _flipCrossAlignment(WrapCrossAlignment alignment) {
  return switch (alignment) {
    WrapCrossAlignment.start => WrapCrossAlignment.end,
    WrapCrossAlignment.end => WrapCrossAlignment.start,
    WrapCrossAlignment.center => WrapCrossAlignment.center,
  };
}

/// Lays out wrap children with a max row count and an overflow slot.
///
/// Children are requested from [childManager] during layout. The overflow count
/// is injected into [RenderOverflowCountBuilder] (LayoutBuilder-style) so the
/// indicator is built in the same frame.
///
/// Packing is always horizontal. [alignment], [runAlignment],
/// [crossAxisAlignment], [textDirection] and [verticalDirection] are applied
/// afterwards, matching [RenderWrap] with `direction: Axis.horizontal`.
class RenderLimitedWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, LimitedWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, LimitedWrapParentData> {
  RenderLimitedWrap({
    required this.childManager,
    int? maxLines,
    required double spacing,
    required double runSpacing,
    WrapAlignment alignment = WrapAlignment.start,
    WrapAlignment runAlignment = WrapAlignment.start,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    Clip clipBehavior = Clip.none,
  }) : _maxLines = maxLines,
       _spacing = spacing,
       _runSpacing = runSpacing,
       _alignment = alignment,
       _runAlignment = runAlignment,
       _crossAxisAlignment = crossAxisAlignment,
       _textDirection = textDirection,
       _verticalDirection = verticalDirection,
       _clipBehavior = clipBehavior;

  /// Creates and removes children during [performLayout].
  final LimitedWrapChildManager childManager;

  int? _maxLines;
  double _spacing;
  double _runSpacing;
  WrapAlignment _alignment;
  WrapAlignment _runAlignment;
  WrapCrossAlignment _crossAxisAlignment;
  TextDirection? _textDirection;
  VerticalDirection _verticalDirection;
  Clip _clipBehavior;

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

  WrapAlignment get alignment => _alignment;
  set alignment(WrapAlignment value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    markNeedsLayout();
  }

  WrapAlignment get runAlignment => _runAlignment;
  set runAlignment(WrapAlignment value) {
    if (_runAlignment == value) {
      return;
    }
    _runAlignment = value;
    markNeedsLayout();
  }

  WrapCrossAlignment get crossAxisAlignment => _crossAxisAlignment;
  set crossAxisAlignment(WrapCrossAlignment value) {
    if (_crossAxisAlignment == value) {
      return;
    }
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  TextDirection? get textDirection => _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  VerticalDirection get verticalDirection => _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection == value) {
      return;
    }
    _verticalDirection = value;
    markNeedsLayout();
  }

  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior == value) {
      return;
    }
    _clipBehavior = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  int _objectsOverflowed = 0;
  bool _hasVisualOverflow = false;
  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! LimitedWrapParentData) {
      child.parentData = LimitedWrapParentData();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(() {
      if (firstChild != null && childAfter(firstChild!) != null) {
        assert(
          textDirection != null,
          'Horizontal $runtimeType with multiple children has a null '
          'textDirection, so the layout order is undefined.',
        );
      }
      if (alignment == WrapAlignment.start || alignment == WrapAlignment.end) {
        assert(
          textDirection != null,
          'Horizontal $runtimeType with alignment $alignment has a null '
          'textDirection, so the alignment cannot be resolved.',
        );
      }
      return true;
    }());
    return true;
  }

  BoxConstraints get _childConstraints {
    return BoxConstraints(maxWidth: constraints.maxWidth);
  }

  bool _isOverflow(RenderBox child) {
    return (child.parentData! as LimitedWrapParentData).isOverflow;
  }

  RenderBox? get _firstItem {
    final child = firstChild;
    if (child == null || _isOverflow(child)) {
      return null;
    }
    return child;
  }

  RenderBox? get _lastItem {
    final child = lastChild;
    if (child == null) {
      return null;
    }
    if (_isOverflow(child)) {
      return childBefore(child);
    }
    return child;
  }

  RenderBox? get _overflowChild {
    final child = lastChild;
    if (child != null && _isOverflow(child)) {
      return child;
    }
    return null;
  }

  RenderBox? _itemAfter(RenderBox after) {
    final next = childAfter(after);
    if (next == null || _isOverflow(next)) {
      return null;
    }
    return next;
  }

  double _overflowStartDx(_Run run) {
    if (run.children.isEmpty) {
      return 0;
    }
    return run.mainAxisExtent + _spacing;
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);
    _objectsOverflowed = 0;
    _hasVisualOverflow = false;

    final childConstraints = _childConstraints;
    final maxWidth = constraints.maxWidth;
    final itemCount = childManager.itemCount;
    final runs = <_Run>[];
    var currentRun = _Run();
    var dx = 0.0;
    var renderedRows = 1;
    var placedCount = 0;
    RenderBox? after;
    var nextExisting = _firstItem;

    for (var index = 0; index < itemCount; index++) {
      final child = _ensureItem(
        index,
        after: after,
        nextExisting: nextExisting,
      );
      child.layout(childConstraints, parentUsesSize: true);
      final childSize = child.size;

      if (_maxLines != null) {
        final wouldExceedLastRow =
            renderedRows == _maxLines &&
            dx + childSize.width + _spacing > maxWidth;
        if (renderedRows > _maxLines! || wouldExceedLastRow) {
          break;
        }
      }

      if (currentRun.children.isNotEmpty &&
          dx + childSize.width + _spacing > maxWidth) {
        runs.add(currentRun);
        currentRun = _Run();
        renderedRows++;
        dx = 0;
      }

      currentRun.add(child, _spacing);
      dx += childSize.width + _spacing;
      placedCount++;
      after = child;
      nextExisting = _itemAfter(child);
    }

    if (currentRun.children.isNotEmpty) {
      runs.add(currentRun);
    }

    _objectsOverflowed = itemCount - placedCount;
    _collectGarbage(placedCount);

    if (_objectsOverflowed > 0) {
      _insertOverflowIntoRuns(runs, childConstraints, maxWidth);
    } else if (_overflowChild != null) {
      invokeLayoutCallback<BoxConstraints>((_) {
        childManager.removeOverflowSlot();
      });
    }

    _positionRuns(runs);
  }

  void _insertOverflowIntoRuns(
    List<_Run> runs,
    BoxConstraints childConstraints,
    double maxWidth,
  ) {
    final overflowRender = _ensureOverflow();
    _layoutOverflowChild(overflowRender, childConstraints);

    if (runs.isEmpty) {
      final run = _Run()..add(overflowRender, _spacing);
      runs.add(run);
      return;
    }

    var currentRun = runs.last;
    while (_overflowStartDx(currentRun) + overflowRender.size.width >
            maxWidth &&
        currentRun.children.isNotEmpty) {
      _hideLastVisibleChild(currentRun);
      _layoutOverflowChild(overflowRender, childConstraints);
    }

    if (currentRun.children.isEmpty && runs.length > 1) {
      final previous = runs[runs.length - 2];
      final candidateDx = previous.mainAxisExtent + _spacing;
      if (candidateDx + overflowRender.size.width <= maxWidth) {
        runs.removeLast();
        previous.add(overflowRender, _spacing);
        return;
      }
    }

    currentRun.add(overflowRender, _spacing);
  }

  void _layoutOverflowChild(
    RenderBox overflowRender,
    BoxConstraints childConstraints,
  ) {
    _setOverflowCount(overflowRender, _objectsOverflowed);
    overflowRender.layout(childConstraints, parentUsesSize: true);
  }

  void _hideLastVisibleChild(_Run run) {
    if (run.children.isEmpty) {
      return;
    }
    final last = run.removeLast(_spacing);
    _objectsOverflowed++;
    _destroyItem(last);
  }

  void _positionRuns(List<_Run> runs) {
    var contentWidth = 0.0;
    var contentHeight = 0.0;
    if (runs.isNotEmpty) {
      for (final run in runs) {
        contentWidth = max(contentWidth, run.mainAxisExtent);
      }
      contentHeight = _runSpacing * (runs.length - 1);
      for (final run in runs) {
        contentHeight += run.crossAxisExtent;
      }
    }

    size = constraints.constrain(Size(contentWidth, contentHeight));
    _hasVisualOverflow =
        contentWidth > size.width || contentHeight > size.height;

    if (runs.isEmpty) {
      return;
    }

    final flipMainAxis = textDirection == TextDirection.rtl;
    final flipCrossAxis = verticalDirection == VerticalDirection.up;
    final crossFreeSpace = max(0.0, size.height - contentHeight);
    final effectiveCrossAlignment =
        flipCrossAxis
            ? _flipCrossAlignment(crossAxisAlignment)
            : crossAxisAlignment;
    final (runLeadingSpace, runBetweenSpace) = _distributeSpace(
      runAlignment,
      crossFreeSpace,
      _runSpacing,
      runs.length,
      flipCrossAxis,
    );

    var runCrossOffset = runLeadingSpace;
    final orderedRuns = flipCrossAxis ? runs.reversed : runs;
    for (final run in orderedRuns) {
      final mainFreeSpace = max(0.0, size.width - run.mainAxisExtent);
      final (childLeadingSpace, childBetweenSpace) = _distributeSpace(
        alignment,
        mainFreeSpace,
        _spacing,
        run.children.length,
        flipMainAxis,
      );

      var childMainOffset = childLeadingSpace;
      final children = flipMainAxis ? run.children.reversed : run.children;
      for (final child in children) {
        final childCrossOffset =
            _crossAlignmentFactor(effectiveCrossAlignment) *
            (run.crossAxisExtent - child.size.height);
        final parentData = child.parentData! as LimitedWrapParentData;
        parentData.offset = Offset(
          childMainOffset,
          runCrossOffset + childCrossOffset,
        );
        childMainOffset += child.size.width + childBetweenSpace;
      }
      runCrossOffset += run.crossAxisExtent + runBetweenSpace;
    }
  }

  RenderBox _ensureItem(
    int index, {
    required RenderBox? after,
    required RenderBox? nextExisting,
  }) {
    if (nextExisting != null) {
      final parentData = nextExisting.parentData! as LimitedWrapParentData;
      if (parentData.index == index) {
        return nextExisting;
      }
    }
    invokeLayoutCallback<BoxConstraints>((_) {
      childManager.createItem(index, after: after);
    });
    final created = after == null ? _firstItem : _itemAfter(after);
    assert(created != null, 'Child manager did not create item $index.');
    return created!;
  }

  void _collectGarbage(int firstUnusedIndex) {
    invokeLayoutCallback<BoxConstraints>((_) {
      while (true) {
        final child = _lastItem;
        if (child == null) {
          return;
        }
        final index = (child.parentData! as LimitedWrapParentData).index;
        if (index == null || index < firstUnusedIndex) {
          return;
        }
        childManager.removeItem(child);
      }
    });
  }

  void _destroyItem(RenderBox child) {
    invokeLayoutCallback<BoxConstraints>((_) {
      childManager.removeItem(child);
    });
  }

  RenderBox _ensureOverflow() {
    final existing = _overflowChild;
    if (existing != null) {
      return existing;
    }
    invokeLayoutCallback<BoxConstraints>((_) {
      childManager.createOverflowSlot(after: _lastItem);
    });
    final created = _overflowChild;
    assert(created != null, 'Child manager did not create the overflow slot.');
    return created!;
  }

  void _setOverflowCount(RenderBox overflowRender, int count) {
    if (overflowRender is! RenderOverflowCountBuilder) {
      return;
    }
    final slot = overflowRender;
    if (slot.overflowCount == count) {
      return;
    }
    invokeLayoutCallback<BoxConstraints>((_) {
      slot.overflowCount = count;
      slot.markNeedsLayout();
    });
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      defaultPaint(context, offset);
    }
  }

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    properties.add(EnumProperty<WrapAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(
      EnumProperty<WrapCrossAlignment>(
        'crossAxisAlignment',
        crossAxisAlignment,
      ),
    );
    properties.add(
      EnumProperty<TextDirection>(
        'textDirection',
        textDirection,
        defaultValue: null,
      ),
    );
    properties.add(
      EnumProperty<VerticalDirection>(
        'verticalDirection',
        verticalDirection,
        defaultValue: VerticalDirection.down,
      ),
    );
    properties.add(
      EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.none),
    );
  }
}
