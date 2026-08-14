import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

Widget sizedChild(
  String text, {
  Key? key,
  double width = 60,
  double height = 30,
}) {
  return SizedBox(
    key: key,
    width: width,
    height: height,
    child: Text(text),
  );
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
          expectVisible(
            tester,
            ValueKey('item_$i'),
            size: const Size(60, 30),
          );
        }
        for (var i = 3; i < 10; i++) {
          expectHidden(tester, ValueKey('item_$i'));
        }
        expect(find.text('Overflow: 7'), findsOneWidget);
        expect(receivedOverflowCount, equals(7));
      },
    );

    testWidgets(
      'hides one more child when overflow indicator does not fit',
      (tester) async {
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

        expectVisible(
          tester,
          const ValueKey('item_0'),
          size: const Size(60, 30),
        );
        expectVisible(
          tester,
          const ValueKey('item_1'),
          size: const Size(60, 30),
        );
        expectHidden(tester, const ValueKey('item_2'));
        expect(find.text('Overflow: 8'), findsOneWidget);
        expect(counts, contains(8));
        expect(counts.last, equals(8));
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
        expectVisible(
          tester,
          ValueKey('item_$i'),
          size: const Size(60, 30),
        );
      }
      expectHidden(tester, const ValueKey('overflow_widget'));
      expect(receivedOverflowCount, equals(0));
    });
  });
}
