import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Builds the overflow indicator from how many wrap children did not fit.
typedef LimitedWrapOverflowBuilder =
    Widget Function(BuildContext context, int overflowCount);

/// Defers building the overflow indicator until layout time, like
/// [LayoutBuilder], but [layoutInfo] is an overflow [int] injected by
/// [RenderExtendedWrap] instead of incoming constraints.
///
/// Rebuild runs inside [performLayout] via [invokeLayoutCallback], so the
/// first paint already shows the final overflow widget.
class OverflowCountBuilder extends AbstractLayoutBuilder<int> {
  const OverflowCountBuilder({super.key, required this.builder});

  @override
  final LimitedWrapOverflowBuilder builder;

  @override
  RenderOverflowCountBuilder createRenderObject(BuildContext context) {
    return RenderOverflowCountBuilder();
  }
}

/// Render object for [OverflowCountBuilder].
///
/// Parent sets [overflowCount] before [layout]; [performLayout] then runs
/// [runLayoutCallback] so [OverflowCountBuilder.builder] builds in-frame.
class RenderOverflowCountBuilder extends RenderBox
    with
        RenderObjectWithChildMixin<RenderBox>,
        RenderObjectWithLayoutCallbackMixin,
        RenderAbstractLayoutBuilderMixin<int, RenderBox> {
  int _overflowCount = 0;

  /// Number of overflowed wrap children; set by the parent wrap before layout.
  int get overflowCount => _overflowCount;

  set overflowCount(int value) {
    if (_overflowCount == value) {
      return;
    }
    _overflowCount = value;
  }

  @override
  int get layoutInfo => _overflowCount;

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry layout would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return Size.zero;
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry baseline would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return null;
  }

  @override
  void performLayout() {
    runLayoutCallback();
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child!.size);
    } else {
      size = Size.zero;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return child?.getDistanceToActualBaseline(baseline) ??
        super.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'OverflowCountBuilder does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require running the layout '
          'callback speculatively, which might mutate the live render object tree.',
        );
      }
      return true;
    }());
    return true;
  }
}
