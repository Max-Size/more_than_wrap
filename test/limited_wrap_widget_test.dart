import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

Widget sizedChild(
  String text, {
  Key? key,
  double width = 60,
  double height = 30,
}) {
  return SizedBox(key: key, width: width, height: height, child: Text(text));
}

void expectVisible(WidgetTester tester, Key key, {required Size size}) {
  expect(find.byKey(key), findsOneWidget);
  expect(tester.getSize(find.byKey(key)), size);
}

void expectNotInTree(Key key) {
  expect(find.byKey(key), findsNothing);
}

Widget wrapHarness({required double width, required LimitedWrap child}) {
  return MaterialApp(
    home: Center(
      child: SizedBox(width: width, child: child),
    ),
  );
}

Widget overflowChild(int count, {double width = 20, double height = 30}) {
  return SizedBox(
    width: width,
    height: height,
    child: Text('Overflow: $count', key: const ValueKey('overflow_widget')),
  );
}

void main() {
  group('LimitedWrap', () {
    testWidgets(
      'builds overflow widget with correct count in the first frame',
      (tester) async {
        int? receivedOverflowCount;
        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 1,
              overflowWidgetBuilder: (context, count) {
                receivedOverflowCount = count;
                return SizedBox(
                  width: 20,
                  height: 30,
                  child: Text(
                    'Overflow: $count',
                    key: const ValueKey('overflow_widget'),
                  ),
                );
              },
              children: List.generate(
                10,
                (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
              ),
            ),
          ),
        );

        for (var i = 0; i < 3; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
        }
        for (var i = 3; i < 10; i++) {
          expectNotInTree(ValueKey('item_$i'));
        }
        expect(find.text('Overflow: 7'), findsOneWidget);
        expect(receivedOverflowCount, equals(7));
      },
    );

    testWidgets('hides one more child when overflow indicator does not fit', (
      tester,
    ) async {
      final counts = <int>[];
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              counts.add(count);
              return SizedBox(
                width: 40,
                height: 30,
                child: Text(
                  'Overflow: $count',
                  key: const ValueKey('overflow_widget'),
                ),
              );
            },
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      expectVisible(tester, const ValueKey('item_0'), size: const Size(60, 30));
      expectVisible(tester, const ValueKey('item_1'), size: const Size(60, 30));
      expectNotInTree(const ValueKey('item_2'));
      expect(find.text('Overflow: 8'), findsOneWidget);
      expect(counts, contains(8));
      expect(counts.last, equals(8));
    });

    testWidgets(
      'hides as many children as needed for overflow to stay in bounds',
      (tester) async {
        late int receivedOverflowCount;
        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 1,
              overflowWidgetBuilder: (context, count) {
                receivedOverflowCount = count;
                return SizedBox(
                  width: 60,
                  height: 30,
                  child: Text(
                    'Overflow: $count',
                    key: const ValueKey('overflow_widget'),
                  ),
                );
              },
              children: List.generate(
                20,
                (i) =>
                    sizedChild('Item $i', key: ValueKey('item_$i'), width: 20),
              ),
            ),
          ),
        );

        for (var i = 0; i < 7; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(20, 30));
        }
        for (var i = 7; i < 20; i++) {
          expectNotInTree(ValueKey('item_$i'));
        }
        expect(find.text('Overflow: 13'), findsOneWidget);
        expect(receivedOverflowCount, equals(13));

        final wrapRect = tester.getRect(find.byType(LimitedWrap));
        final overflowRect = tester.getRect(
          find.byKey(const ValueKey('overflow_widget')),
        );
        expect(overflowRect.right, lessThanOrEqualTo(wrapRect.right));
        expect(overflowRect.left, greaterThanOrEqualTo(wrapRect.left));
      },
    );

    testWidgets(
      'keeps previous row intact when last row is emptied for overflow',
      (tester) async {
        late int receivedOverflowCount;
        await tester.pumpWidget(
          wrapHarness(
            width: 100,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 2,
              overflowWidgetBuilder: (context, count) {
                receivedOverflowCount = count;
                return SizedBox(
                  width: 50,
                  height: 30,
                  child: Text(
                    'Overflow: $count',
                    key: const ValueKey('overflow_widget'),
                  ),
                );
              },
              children: List.generate(
                4,
                (i) =>
                    sizedChild('Item $i', key: ValueKey('item_$i'), width: 80),
              ),
            ),
          ),
        );

        expectVisible(
          tester,
          const ValueKey('item_0'),
          size: const Size(80, 30),
        );
        expectNotInTree(const ValueKey('item_1'));
        expectNotInTree(const ValueKey('item_2'));
        expectNotInTree(const ValueKey('item_3'));
        expect(find.text('Overflow: 3'), findsOneWidget);
        expect(receivedOverflowCount, equals(3));

        final wrapRect = tester.getRect(find.byType(LimitedWrap));
        final overflowRect = tester.getRect(
          find.byKey(const ValueKey('overflow_widget')),
        );
        expect(overflowRect.right, lessThanOrEqualTo(wrapRect.right));
      },
    );

    testWidgets(
      'moves overflow onto previous row when last row is emptied and it fits',
      (tester) async {
        late int receivedOverflowCount;
        await tester.pumpWidget(
          wrapHarness(
            width: 100,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 2,
              overflowWidgetBuilder: (context, count) {
                receivedOverflowCount = count;
                return SizedBox(
                  width: 50,
                  height: 30,
                  child: Text(
                    'Overflow: $count',
                    key: const ValueKey('overflow_widget'),
                  ),
                );
              },
              children: [
                sizedChild('Item 0', key: const ValueKey('item_0'), width: 40),
                sizedChild('Item 1', key: const ValueKey('item_1'), width: 80),
                sizedChild('Item 2', key: const ValueKey('item_2'), width: 80),
                sizedChild('Item 3', key: const ValueKey('item_3'), width: 80),
              ],
            ),
          ),
        );

        expectVisible(
          tester,
          const ValueKey('item_0'),
          size: const Size(40, 30),
        );
        expectNotInTree(const ValueKey('item_1'));
        expectNotInTree(const ValueKey('item_2'));
        expectNotInTree(const ValueKey('item_3'));
        expect(find.text('Overflow: 3'), findsOneWidget);
        expect(receivedOverflowCount, equals(3));

        final wrapRect = tester.getRect(find.byType(LimitedWrap));
        final overflowRect = tester.getRect(
          find.byKey(const ValueKey('overflow_widget')),
        );
        expect(wrapRect.height, equals(30));
        expect(overflowRect.left, equals(wrapRect.left + 40));
        expect(overflowRect.right, lessThanOrEqualTo(wrapRect.right));
      },
    );

    testWidgets('does not mount overflow slot when all children fit', (
      tester,
    ) async {
      var builderCalled = false;
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              builderCalled = true;
              return SizedBox(
                key: const ValueKey('overflow_widget'),
                width: 40,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
            children: List.generate(
              3,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('overflow_widget'));
      expect(builderCalled, isFalse);
    });

    testWidgets('does not build children that are never measured', (
      tester,
    ) async {
      final buildCounts = List<int>.filled(10, 0);
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              return SizedBox(
                width: 20,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
            children: List.generate(10, (i) {
              return Builder(
                key: ValueKey('item_$i'),
                builder: (context) {
                  buildCounts[i]++;
                  return sizedChild('Item $i');
                },
              );
            }),
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        expect(buildCounts[i], greaterThan(0));
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      // Item 3 is created to measure, then unmounted.
      expect(buildCounts[3], greaterThan(0));
      expectNotInTree(const ValueKey('item_3'));
      for (var i = 4; i < 10; i++) {
        expect(buildCounts[i], 0);
        expectNotInTree(ValueKey('item_$i'));
      }
    });

    testWidgets('mounts more children when constraints grow', (tester) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              return SizedBox(
                width: 20,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      expectVisible(tester, const ValueKey('item_0'), size: const Size(60, 30));
      expectNotInTree(const ValueKey('item_3'));

      await tester.pumpWidget(
        wrapHarness(
          width: 400,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              return SizedBox(
                width: 20,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expect(find.text('Overflow: 4'), findsOneWidget);
    });

    testWidgets('unmounts children that no longer fit after shrink', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 400,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              return SizedBox(
                width: 20,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      expectVisible(tester, const ValueKey('item_5'), size: const Size(60, 30));

      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              return SizedBox(
                width: 20,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      expectVisible(tester, const ValueKey('item_0'), size: const Size(60, 30));
      expectVisible(tester, const ValueKey('item_1'), size: const Size(60, 30));
      expectVisible(tester, const ValueKey('item_2'), size: const Size(60, 30));
      expectNotInTree(const ValueKey('item_3'));
      expectNotInTree(const ValueKey('item_5'));
      expect(find.text('Overflow: 7'), findsOneWidget);
    });

    testWidgets('builder does not construct widgets past the measured prefix', (
      tester,
    ) async {
      final buildCounts = List<int>.filled(10, 0);
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap.builder(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            itemCount: 10,
            itemBuilder: (context, i) {
              buildCounts[i]++;
              return sizedChild('Item $i', key: ValueKey('item_$i'));
            },
            overflowWidgetBuilder: (context, count) {
              return SizedBox(
                width: 20,
                height: 30,
                child: Text('Overflow: $count'),
              );
            },
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        expect(buildCounts[i], greaterThan(0));
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expect(buildCounts[3], greaterThan(0));
      expectNotInTree(const ValueKey('item_3'));
      for (var i = 4; i < 10; i++) {
        expect(buildCounts[i], 0);
        expectNotInTree(ValueKey('item_$i'));
      }
      expect(find.text('Overflow: 7'), findsOneWidget);
    });

    testWidgets('wraps onto extra rows when maxLines is unlimited', (
      tester,
    ) async {
      var builderCalled = false;
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            overflowWidgetBuilder: (context, count) {
              builderCalled = true;
              return overflowChild(count);
            },
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      for (var i = 0; i < 10; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('overflow_widget'));
      expect(builderCalled, isFalse);
      expect(tester.getSize(find.byType(LimitedWrap)).height, equals(120));
    });

    testWidgets('places overflow on the last row next to remaining children', (
      tester,
    ) async {
      late int receivedOverflowCount;
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 2,
            overflowWidgetBuilder: (context, count) {
              receivedOverflowCount = count;
              return overflowChild(count);
            },
            children: List.generate(
              8,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('item_6'));
      expectNotInTree(const ValueKey('item_7'));
      expect(find.text('Overflow: 2'), findsOneWidget);
      expect(receivedOverflowCount, equals(2));

      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final lastItemRect = tester.getRect(find.byKey(const ValueKey('item_5')));
      final overflowRect = tester.getRect(
        find.byKey(const ValueKey('overflow_widget')),
      );
      expect(wrapRect.height, equals(60));
      expect(overflowRect.top, equals(lastItemRect.top));
      expect(overflowRect.left, equals(lastItemRect.right));
      expect(overflowRect.right, lessThanOrEqualTo(wrapRect.right));
    });

    testWidgets(
      'applies spacing and runSpacing when wrapping and overflowing',
      (tester) async {
        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 10,
              runSpacing: 8,
              maxLines: 2,
              overflowWidgetBuilder: (context, count) => overflowChild(count),
              children: List.generate(
                7,
                (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
              ),
            ),
          ),
        );

        for (var i = 0; i < 4; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
        }
        expectNotInTree(const ValueKey('item_4'));
        expect(find.text('Overflow: 3'), findsOneWidget);

        final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
        final item1 = tester.getRect(find.byKey(const ValueKey('item_1')));
        final item2 = tester.getRect(find.byKey(const ValueKey('item_2')));
        final item3 = tester.getRect(find.byKey(const ValueKey('item_3')));
        final overflowRect = tester.getRect(
          find.byKey(const ValueKey('overflow_widget')),
        );

        expect(item1.left, equals(item0.right + 10));
        expect(item2.top, equals(item0.bottom + 8));
        expect(item3.left, equals(item2.right + 10));
        expect(overflowRect.top, equals(item3.top));
        expect(overflowRect.left, equals(item3.right + 10));
        expect(tester.getSize(find.byType(LimitedWrap)).height, equals(68));
      },
    );

    testWidgets(
      'shows more rows when maxLines increases and all when unlimited',
      (tester) async {
        List<Widget> items() => List.generate(
          10,
          (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
        );

        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 1,
              overflowWidgetBuilder: (context, count) => overflowChild(count),
              children: items(),
            ),
          ),
        );

        expectVisible(
          tester,
          const ValueKey('item_2'),
          size: const Size(60, 30),
        );
        expectNotInTree(const ValueKey('item_3'));
        expect(find.text('Overflow: 7'), findsOneWidget);

        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 2,
              overflowWidgetBuilder: (context, count) => overflowChild(count),
              children: items(),
            ),
          ),
        );

        for (var i = 0; i < 6; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
        }
        expectNotInTree(const ValueKey('item_6'));
        expect(find.text('Overflow: 4'), findsOneWidget);

        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              overflowWidgetBuilder: (context, count) => overflowChild(count),
              children: items(),
            ),
          ),
        );

        for (var i = 0; i < 10; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
        }
        expectNotInTree(const ValueKey('overflow_widget'));
      },
    );

    testWidgets('adds and removes overflow slot when children count changes', (
      tester,
    ) async {
      var builderCalled = false;

      LimitedWrap wrap(int count) {
        return LimitedWrap(
          spacing: 0,
          runSpacing: 0,
          maxLines: 1,
          overflowWidgetBuilder: (context, overflowCount) {
            builderCalled = true;
            return overflowChild(overflowCount);
          },
          children: List.generate(
            count,
            (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
          ),
        );
      }

      await tester.pumpWidget(wrapHarness(width: 200, child: wrap(3)));

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('overflow_widget'));
      expect(builderCalled, isFalse);

      await tester.pumpWidget(wrapHarness(width: 200, child: wrap(10)));

      expectNotInTree(const ValueKey('item_3'));
      expect(find.text('Overflow: 7'), findsOneWidget);
      expect(builderCalled, isTrue);

      builderCalled = false;
      await tester.pumpWidget(wrapHarness(width: 200, child: wrap(3)));

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('item_3'));
      expectNotInTree(const ValueKey('overflow_widget'));
    });

    testWidgets('builder updates mounted prefix when itemCount changes', (
      tester,
    ) async {
      final buildCounts = List<int>.filled(10, 0);

      LimitedWrap wrap(int itemCount) {
        return LimitedWrap.builder(
          spacing: 0,
          runSpacing: 0,
          maxLines: 1,
          itemCount: itemCount,
          itemBuilder: (context, i) {
            buildCounts[i]++;
            return sizedChild('Item $i', key: ValueKey('item_$i'));
          },
          overflowWidgetBuilder: (context, count) => overflowChild(count),
        );
      }

      await tester.pumpWidget(wrapHarness(width: 200, child: wrap(10)));

      expect(find.text('Overflow: 7'), findsOneWidget);
      expect(buildCounts[3], greaterThan(0));
      expect(buildCounts[4], 0);

      await tester.pumpWidget(wrapHarness(width: 200, child: wrap(3)));

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('item_3'));
      expectNotInTree(const ValueKey('overflow_widget'));

      await tester.pumpWidget(wrapHarness(width: 200, child: wrap(10)));

      expectNotInTree(const ValueKey('item_3'));
      expect(find.text('Overflow: 7'), findsOneWidget);
      for (var i = 4; i < 10; i++) {
        expect(buildCounts[i], 0);
        expectNotInTree(ValueKey('item_$i'));
      }
    });

    testWidgets('does not mount children or overflow for an empty list', (
      tester,
    ) async {
      var builderCalled = false;
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: (context, count) {
              builderCalled = true;
              return overflowChild(count);
            },
            children: const [],
          ),
        ),
      );

      expect(find.byType(LimitedWrap), findsOneWidget);
      expect(tester.getSize(find.byType(LimitedWrap)), const Size(200, 0));
      expectNotInTree(const ValueKey('overflow_widget'));
      expect(builderCalled, isFalse);
    });

    testWidgets('builder with itemCount 0 has zero size and no overflow', (
      tester,
    ) async {
      var itemBuilderCalled = false;
      var overflowBuilderCalled = false;
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap.builder(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            itemCount: 0,
            itemBuilder: (context, i) {
              itemBuilderCalled = true;
              return sizedChild('Item $i', key: ValueKey('item_$i'));
            },
            overflowWidgetBuilder: (context, count) {
              overflowBuilderCalled = true;
              return overflowChild(count);
            },
          ),
        ),
      );

      expect(tester.getSize(find.byType(LimitedWrap)), const Size(200, 0));
      expectNotInTree(const ValueKey('overflow_widget'));
      expect(itemBuilderCalled, isFalse);
      expect(overflowBuilderCalled, isFalse);
    });

    testWidgets(
      'omitting overflowWidgetBuilder hides extra children without an indicator',
      (tester) async {
        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 1,
              children: List.generate(
                10,
                (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
              ),
            ),
          ),
        );

        for (var i = 0; i < 3; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
        }
        for (var i = 3; i < 10; i++) {
          expectNotInTree(ValueKey('item_$i'));
        }
        expectNotInTree(const ValueKey('overflow_widget'));
        expect(tester.getSize(find.byType(LimitedWrap)).height, equals(30));
      },
    );

    testWidgets('removing overflowWidgetBuilder unmounts the overflow slot', (
      tester,
    ) async {
      Widget wrap({LimitedWrapOverflowBuilder? overflowBuilder}) {
        return wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            maxLines: 1,
            overflowWidgetBuilder: overflowBuilder,
            children: List.generate(
              10,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        wrap(overflowBuilder: (context, count) => overflowChild(count)),
      );
      expect(find.text('Overflow: 7'), findsOneWidget);

      await tester.pumpWidget(wrap());

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectNotInTree(const ValueKey('item_3'));
      expectNotInTree(const ValueKey('overflow_widget'));
    });
  });

  group('LimitedWrap Wrap-compatible alignment', () {
    testWidgets('alignment end packs the run towards the trailing edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            alignment: WrapAlignment.end,
            overflowWidgetBuilder: (_, count) => overflowChild(count),
            children: List.generate(
              3,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
      final item2 = tester.getRect(find.byKey(const ValueKey('item_2')));
      expect(item0.left, equals(wrapRect.left + 20));
      expect(item2.right, equals(wrapRect.right));
    });

    testWidgets('alignment center centers the run in the available width', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            overflowWidgetBuilder: (_, count) => overflowChild(count),
            children: List.generate(
              3,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
      final item2 = tester.getRect(find.byKey(const ValueKey('item_2')));
      expect(item0.left, equals(wrapRect.left + 10));
      expect(item2.right, equals(wrapRect.right - 10));
    });

    testWidgets('RTL start places the first child at the trailing edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            textDirection: TextDirection.rtl,
            overflowWidgetBuilder: (_, count) => overflowChild(count),
            children: List.generate(
              3,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
      final item2 = tester.getRect(find.byKey(const ValueKey('item_2')));
      expect(item0.right, equals(wrapRect.right));
      expect(item2.left, equals(wrapRect.left + 20));
    });

    testWidgets(
      'RTL overflow sits at the leading (left) edge of the last run',
      (tester) async {
        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              maxLines: 1,
              textDirection: TextDirection.rtl,
              overflowWidgetBuilder: (_, count) => overflowChild(count),
              children: List.generate(
                10,
                (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
              ),
            ),
          ),
        );

        final wrapRect = tester.getRect(find.byType(LimitedWrap));
        final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
        final overflowRect = tester.getRect(
          find.byKey(const ValueKey('overflow_widget')),
        );
        expect(item0.right, equals(wrapRect.right));
        expect(overflowRect.left, equals(wrapRect.left));
        expect(overflowRect.right, lessThanOrEqualTo(item0.left));
      },
    );

    testWidgets(
      'crossAxisAlignment end aligns shorter children to the bottom',
      (tester) async {
        await tester.pumpWidget(
          wrapHarness(
            width: 200,
            child: LimitedWrap(
              spacing: 0,
              runSpacing: 0,
              crossAxisAlignment: WrapCrossAlignment.end,
              overflowWidgetBuilder: (_, count) => overflowChild(count),
              children: [
                sizedChild('A', key: const ValueKey('item_0'), height: 20),
                sizedChild('B', key: const ValueKey('item_1'), height: 40),
              ],
            ),
          ),
        );

        final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
        final item1 = tester.getRect(find.byKey(const ValueKey('item_1')));
        expect(item0.bottom, equals(item1.bottom));
        expect(item0.top, equals(item1.top + 20));
      },
    );

    testWidgets('verticalDirection up paints the first run at the bottom', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            verticalDirection: VerticalDirection.up,
            overflowWidgetBuilder: (_, count) => overflowChild(count),
            children: List.generate(
              6,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
      final item3 = tester.getRect(find.byKey(const ValueKey('item_3')));
      expect(wrapRect.height, equals(60));
      expect(item0.bottom, equals(wrapRect.bottom));
      expect(item3.top, equals(wrapRect.top));
    });

    testWidgets('runAlignment end places runs at the bottom of extra height', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: LimitedWrap(
                spacing: 0,
                runSpacing: 0,
                runAlignment: WrapAlignment.end,
                overflowWidgetBuilder: (_, count) => overflowChild(count),
                children: List.generate(
                  3,
                  (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
                ),
              ),
            ),
          ),
        ),
      );

      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
      expect(wrapRect.height, equals(100));
      expect(item0.bottom, equals(wrapRect.bottom));
      expect(item0.top, equals(wrapRect.bottom - 30));
    });

    testWidgets('clipBehavior is accepted without changing default layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHarness(
          width: 200,
          child: LimitedWrap(
            spacing: 0,
            runSpacing: 0,
            clipBehavior: Clip.hardEdge,
            overflowWidgetBuilder: (_, count) => overflowChild(count),
            children: List.generate(
              3,
              (i) => sizedChild('Item $i', key: ValueKey('item_$i')),
            ),
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      final wrapRect = tester.getRect(find.byType(LimitedWrap));
      final item0 = tester.getRect(find.byKey(const ValueKey('item_0')));
      expect(item0.left, equals(wrapRect.left));
    });
  });
}
