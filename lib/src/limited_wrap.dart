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
    this.spacing = 0,
    this.runSpacing = 0,
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
    this.spacing = 0,
    this.runSpacing = 0,
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

  /// Horizontal gap between items in a row.
  final double spacing;

  /// Vertical gap between rows.
  final double runSpacing;

  @override
  RenderObjectElement createElement() => LimitedWrapElement(this);

  @override
  RenderLimitedWrap createRenderObject(BuildContext context) {
    return RenderLimitedWrap(
      childManager: context as LimitedWrapChildManager,
      maxLines: maxLines,
      spacing: spacing,
      runSpacing: runSpacing,
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
      ..runSpacing = runSpacing;
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

/// Lays out wrap children with a max row count and an overflow slot.
///
/// Children are requested from [childManager] during layout. The overflow count
/// is injected into [RenderOverflowCountBuilder] (LayoutBuilder-style) so the
/// indicator is built in the same frame.
class RenderLimitedWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, LimitedWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, LimitedWrapParentData> {
  RenderLimitedWrap({
    required this.childManager,
    int? maxLines,
    required double spacing,
    required double runSpacing,
  }) : _maxLines = maxLines,
       _spacing = spacing,
       _runSpacing = runSpacing;

  /// Creates and removes children during [performLayout].
  final LimitedWrapChildManager childManager;

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
  final List<RenderBox> _placed = [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! LimitedWrapParentData) {
      child.parentData = LimitedWrapParentData();
    }
  }

  @override
  BoxConstraints get constraints =>
      super.constraints.copyWith(minWidth: 0, minHeight: 0);

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

  @override
  void performLayout() {
    _objectsOverflowed = 0;
    _dx = 0;
    _dy = 0;
    _maxYPerRow = 0;
    _placed.clear();

    final itemCount = childManager.itemCount;
    var renderedRows = 1;
    var hasOverflow = false;
    RenderBox? after;
    var nextExisting = _firstItem;

    for (var index = 0; index < itemCount; index++) {
      final child = _ensureItem(
        index,
        after: after,
        nextExisting: nextExisting,
      );
      child.layout(constraints, parentUsesSize: true);
      final childSize = child.size;

      if (_maxLines != null) {
        final wouldExceedLastRow =
            renderedRows == _maxLines &&
            _dx + childSize.width + _spacing > constraints.maxWidth;
        if (renderedRows > _maxLines! || wouldExceedLastRow) {
          hasOverflow = true;
          break;
        }
      }

      if (_dx + childSize.width + _spacing > constraints.maxWidth) {
        renderedRows++;
        _dx = 0;
        _dy += _maxYPerRow + _runSpacing;
        _maxYPerRow = 0;
      }

      final parentData = child.parentData! as LimitedWrapParentData;
      parentData.offset = Offset(_dx, _dy);

      _dx += childSize.width + _spacing;
      _placed.add(child);
      _maxYPerRow = max(_maxYPerRow, childSize.height);
      after = child;
      nextExisting = _itemAfter(child);
    }

    _objectsOverflowed = itemCount - _placed.length;
    hasOverflow = _objectsOverflowed > 0;
    _collectGarbage(_placed.length);

    _layoutOverflowSlot(hasOverflow);

    var rowHeight = _maxYPerRow;
    final overflowRender = _overflowChild;
    if (hasOverflow && overflowRender != null) {
      rowHeight = max(rowHeight, overflowRender.size.height);
    }
    final height = max(_dy + rowHeight, constraints.minHeight);
    size = constraints.constrain(Size(constraints.maxWidth, height));
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

  void _layoutOverflowSlot(bool hasOverflow) {
    if (!hasOverflow) {
      if (_overflowChild != null) {
        invokeLayoutCallback<BoxConstraints>((_) {
          childManager.removeOverflowSlot();
        });
      }
      return;
    }

    final overflowRender = _ensureOverflow();
    _layoutOverflowChild(overflowRender, _objectsOverflowed);

    while (_overflowExceedsMaxWidth(overflowRender) &&
        _lastPlacedIsOnCurrentRow()) {
      _hideLastVisibleChild();
      _layoutOverflowChild(overflowRender, _objectsOverflowed);
    }

    _tryCollapseOverflowOntoPreviousRow(overflowRender);
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

  void _layoutOverflowChild(RenderBox overflowRender, int count) {
    _setOverflowCount(overflowRender, count);
    overflowRender.layout(constraints, parentUsesSize: true);
    final parentData = overflowRender.parentData! as LimitedWrapParentData;
    parentData.offset = Offset(_dx, _dy);
  }

  bool _overflowExceedsMaxWidth(RenderBox overflowRender) {
    return _dx + overflowRender.size.width > constraints.maxWidth;
  }

  bool _lastPlacedIsOnCurrentRow() {
    if (_placed.isEmpty) {
      return false;
    }
    final parentData = _placed.last.parentData! as LimitedWrapParentData;
    return parentData.offset.dy == _dy;
  }

  double _rowMaxHeight(double dy) {
    var maxHeight = 0.0;
    for (final child in _placed) {
      final parentData = child.parentData! as LimitedWrapParentData;
      if (parentData.offset.dy == dy) {
        maxHeight = max(maxHeight, child.size.height);
      }
    }
    return maxHeight;
  }

  void _hideLastVisibleChild() {
    if (_placed.isEmpty) {
      return;
    }

    final last = _placed.removeLast();
    _objectsOverflowed++;
    _syncCursorToPlaced();
    _destroyItem(last);
  }

  void _syncCursorToPlaced() {
    if (_placed.isEmpty) {
      _dx = 0;
      _dy = 0;
      _maxYPerRow = 0;
      return;
    }

    final last = _placed.last;
    final parentData = last.parentData! as LimitedWrapParentData;
    if (parentData.offset.dy == _dy) {
      _dx = parentData.offset.dx + last.size.width + _spacing;
      _maxYPerRow = _rowMaxHeight(_dy);
      return;
    }

    // Current row is empty; keep it so overflow can use the full width.
    _dx = 0;
    _maxYPerRow = 0;
  }

  /// If the last row now contains only the overflow slot, move it onto the
  /// previous row when it fits — avoids a nearly empty extra line.
  void _tryCollapseOverflowOntoPreviousRow(RenderBox overflowRender) {
    if (_placed.isEmpty || _lastPlacedIsOnCurrentRow()) {
      return;
    }

    final last = _placed.last;
    final parentData = last.parentData! as LimitedWrapParentData;
    final candidateDx = parentData.offset.dx + last.size.width + _spacing;
    if (candidateDx + overflowRender.size.width > constraints.maxWidth) {
      return;
    }

    _dx = candidateDx;
    _dy = parentData.offset.dy;
    _maxYPerRow = _rowMaxHeight(_dy);

    final overflowParentData =
        overflowRender.parentData! as LimitedWrapParentData;
    overflowParentData.offset = Offset(_dx, _dy);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
