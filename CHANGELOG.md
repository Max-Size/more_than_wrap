## 1.0.0

First stable release of the rewritten layout engine. Overflow is a real widget, finalized in the same layout pass, and children that do not fit are not kept in the tree.

### Breaking changes (from 0.0.1)

* Replaced `LimitedWrapWidget` with `LimitedWrap`.
* Removed the canvas styler API (`overflowBuilderStyle` / painted overflow text).
* `overflowWidgetBuilder` is now `Widget Function(BuildContext context, int overflowCount)` and is invoked only when overflow exists (`count` is always `> 0`).
* `LimitedWrap.builder` builds **children** lazily (`itemCount` + `itemBuilder`), not the overflow widget.
* Requires Flutter `>= 3.32.0` (overflow slot uses `AbstractLayoutBuilder`).

### Added

* Lazy inflate: only the visible prefix (plus the overflow slot) is mounted; overflowed items are never left in the tree.
* In-layout overflow builder: the indicator is built and can be relaid out several times during one parent layout, so the first frame already shows the correct `+N`.
* If the overflow widget does not fit on the last row, further children are hidden until it does; if that empties the last row, the indicator may move onto the previous row.
* Wrap-compatible packing: `alignment`, `runAlignment`, `crossAxisAlignment`, `textDirection`, `verticalDirection`, `clipBehavior` (direction remains horizontal).
* Interactive example app and GitHub Pages [live demo](https://max-size.github.io/more_than_wrap/).

### Changed

* `overflowWidgetBuilder` is optional. Omit it to unmount overflowed children without showing an indicator.

### Fixed

* Layout jank / extra frame when the overflow count changed (the 0.0.1 builder measured after paint).
* Overflow indicator overflowing the last row when it was wider than the remaining space.

## 0.0.2

Breaking rewrite of the layout engine and public API. Overflow is now a real widget, finalized in the same layout pass, and children that do not fit are not kept in the tree.

### Breaking changes

* Replaced `LimitedWrapWidget` with `LimitedWrap`.
* Removed the canvas styler API (`overflowBuilderStyle` / painted overflow text).
* `overflowWidgetBuilder` is now `Widget Function(BuildContext context, int overflowCount)` and is invoked only when overflow exists (`count` is always `> 0`).
* `LimitedWrap.builder` builds **children** lazily (`itemCount` + `itemBuilder`), not the overflow widget.
* Requires Flutter `>= 3.32.0` (overflow slot uses `AbstractLayoutBuilder`).

### Added

* Lazy inflate: only the visible prefix (plus the overflow slot) is mounted; overflowed items are never left in the tree.
* In-layout overflow builder: the indicator is built and can be relaid out several times during one parent layout, so the first frame already shows the correct `+N`.
* If the overflow widget does not fit on the last row, further children are hidden until it does; if that empties the last row, the indicator may move onto the previous row.
* Wrap-compatible packing: `alignment`, `runAlignment`, `crossAxisAlignment`, `textDirection`, `verticalDirection`, `clipBehavior` (direction remains horizontal).
* Interactive example app and GitHub Pages [live demo](https://max-size.github.io/more_than_wrap/).

### Fixed

* Layout jank / extra frame when the overflow count changed (the 0.0.1 builder measured after paint).
* Overflow indicator overflowing the last row when it was wider than the remaining space.

## 0.0.1

* Initial release of more_than_wrap package
* Added LimitedWrapWidget with limited row functionality
* Added overflow widget support with builder pattern
* Added custom render objects for efficient layout calculations
* Added spacing and runSpacing configuration options
* Added maxLines parameter for row limitation
* Added overflow notification callback system
