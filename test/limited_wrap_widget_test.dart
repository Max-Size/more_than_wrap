import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

Widget sizedChild(String text, {Key? key, double width = 60, double height = 30}) {
  return SizedBox(
    width: width,
    height: height,
    child: Text(text, key: key),
  );
}

void main() {
  group('LimitedWrapWidget (overflowBuilderStyle)', () {
    testWidgets('shows only up to maxLines of children and displays overflow indicator', (tester) async {
      // Container width: 200, child width: 60, so 3 fit per row (with spacing 0)
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: LimitedWrapWidget(
                children: List.generate(10, (i) => sizedChild('Item $i', key: ValueKey('item_$i'))),
                spacing: 0,
                runSpacing: 0,
                maxLines: 1,
                overflowBuilderStyle: OverflowBuilderStyle(
                  textBuilder: (count) => '+$count more',
                  textStyle: const TextStyle(fontSize: 14, color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ),
        ),
      );

      // Only 3 children should be visible in the first row
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('item_$i')), findsOneWidget);
      }
      for (var i = 3; i < 10; i++) {
        expect(find.byKey(ValueKey('item_$i')), findsNothing);
      }
      // The overflow indicator should be present
      expect(find.textContaining('more'), findsOneWidget);
    });

    testWidgets('does not show overflow indicator if all children fit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: LimitedWrapWidget(
                children: List.generate(3, (i) => sizedChild('Item $i', key: ValueKey('item_$i'))),
                spacing: 0,
                runSpacing: 0,
                maxLines: 1,
                overflowBuilderStyle: OverflowBuilderStyle(
                  textBuilder: (count) => '+$count more',
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('item_$i')), findsOneWidget);
      }
      expect(find.textContaining('more'), findsNothing);
    });
  });

  group('LimitedWrapWidget.builder (overflowWidgetBuilder)', () {
    testWidgets('calls overflowWidgetBuilder with correct count and displays it', (tester) async {
      int? receivedOverflowCount;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: LimitedWrapWidget.builder(
                children: List.generate(10, (i) => sizedChild('Item $i', key: ValueKey('item_$i'))),
                spacing: 0,
                runSpacing: 0,
                maxLines: 1,
                overflowWidgetBuilder: (count) {
                  receivedOverflowCount = count;
                  return Text('Overflow: $count', key: const ValueKey('overflow_widget'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Only 3 children should be visible
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('item_$i')), findsOneWidget);
      }
      for (var i = 3; i < 10; i++) {
        expect(find.byKey(ValueKey('item_$i')), findsNothing);
      }
      expect(find.byKey(const ValueKey('overflow_widget')), findsOneWidget);
      expect(receivedOverflowCount, isNotNull);
      expect(receivedOverflowCount, equals(7));
    });

    testWidgets('does not call overflowWidgetBuilder if all children fit', (tester) async {
      int? receivedOverflowCount;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: LimitedWrapWidget.builder(
                children: List.generate(3, (i) => sizedChild('Item $i', key: ValueKey('item_$i'))),
                spacing: 0,
                runSpacing: 0,
                maxLines: 1,
                overflowWidgetBuilder: (count) {
                  receivedOverflowCount = count;
                  return Text('Overflow: $count', key: const ValueKey('overflow_widget'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('item_$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('overflow_widget')), findsNothing);
      expect(receivedOverflowCount, isNull);
    });
  });
} 