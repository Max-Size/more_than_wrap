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

void expectHidden(WidgetTester tester, Key key) {
  expect(find.byKey(key), findsOneWidget);
  expect(tester.getSize(find.byKey(key)), Size.zero);
}

void expectVisible(WidgetTester tester, Key key, {required Size size}) {
  expect(find.byKey(key), findsOneWidget);
  expect(tester.getSize(find.byKey(key)), size);
}

void main() {
  group('LimitedWrapWidget', () {
    testWidgets(
      'builds overflow widget with correct count in the first frame',
      (tester) async {
        int? receivedOverflowCount;
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 200,
                child: LimitedWrapWidget(
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
            ),
          ),
        );

        for (var i = 0; i < 3; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
        }
        for (var i = 3; i < 10; i++) {
          expectHidden(tester, ValueKey('item_$i'));
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
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: LimitedWrapWidget(
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
          ),
        ),
      );

      expectVisible(tester, const ValueKey('item_0'), size: const Size(60, 30));
      expectVisible(tester, const ValueKey('item_1'), size: const Size(60, 30));
      expectHidden(tester, const ValueKey('item_2'));
      expect(find.text('Overflow: 8'), findsOneWidget);
      expect(counts, contains(8));
      expect(counts.last, equals(8));
    });

    testWidgets(
      'hides as many children as needed for overflow to stay in bounds',
      (tester) async {
        late int receivedOverflowCount;
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 200,
                child: LimitedWrapWidget(
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
                    (i) => sizedChild(
                      'Item $i',
                      key: ValueKey('item_$i'),
                      width: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        for (var i = 0; i < 7; i++) {
          expectVisible(tester, ValueKey('item_$i'), size: const Size(20, 30));
        }
        for (var i = 7; i < 20; i++) {
          expectHidden(tester, ValueKey('item_$i'));
        }
        expect(find.text('Overflow: 13'), findsOneWidget);
        expect(receivedOverflowCount, equals(13));

        final wrapRect = tester.getRect(find.byType(LimitedWrapWidget));
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
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                child: LimitedWrapWidget(
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
                    (i) => sizedChild(
                      'Item $i',
                      key: ValueKey('item_$i'),
                      width: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expectVisible(
          tester,
          const ValueKey('item_0'),
          size: const Size(80, 30),
        );
        expectHidden(tester, const ValueKey('item_1'));
        expectHidden(tester, const ValueKey('item_2'));
        expectHidden(tester, const ValueKey('item_3'));
        expect(find.text('Overflow: 3'), findsOneWidget);
        expect(receivedOverflowCount, equals(3));

        final wrapRect = tester.getRect(find.byType(LimitedWrapWidget));
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
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                child: LimitedWrapWidget(
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
                    sizedChild(
                      'Item 0',
                      key: const ValueKey('item_0'),
                      width: 40,
                    ),
                    sizedChild(
                      'Item 1',
                      key: const ValueKey('item_1'),
                      width: 80,
                    ),
                    sizedChild(
                      'Item 2',
                      key: const ValueKey('item_2'),
                      width: 80,
                    ),
                    sizedChild(
                      'Item 3',
                      key: const ValueKey('item_3'),
                      width: 80,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expectVisible(
          tester,
          const ValueKey('item_0'),
          size: const Size(40, 30),
        );
        expectHidden(tester, const ValueKey('item_1'));
        expectHidden(tester, const ValueKey('item_2'));
        expectHidden(tester, const ValueKey('item_3'));
        expect(find.text('Overflow: 3'), findsOneWidget);
        expect(receivedOverflowCount, equals(3));

        final wrapRect = tester.getRect(find.byType(LimitedWrapWidget));
        final overflowRect = tester.getRect(
          find.byKey(const ValueKey('overflow_widget')),
        );
        expect(wrapRect.height, equals(30));
        expect(overflowRect.left, equals(wrapRect.left + 40));
        expect(overflowRect.right, lessThanOrEqualTo(wrapRect.right));
      },
    );

    testWidgets('shrinks overflow slot when all children fit', (tester) async {
      late int receivedOverflowCount;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: LimitedWrapWidget(
                spacing: 0,
                runSpacing: 0,
                maxLines: 1,
                overflowWidgetBuilder: (context, count) {
                  receivedOverflowCount = count;
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
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        expectVisible(tester, ValueKey('item_$i'), size: const Size(60, 30));
      }
      expectHidden(tester, const ValueKey('overflow_widget'));
      expect(receivedOverflowCount, equals(0));
    });
  });
}
