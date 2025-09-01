import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:more_than_wrap/more_than_wrap.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider Control Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SliderControlWidget(),
    );
  }
}

class SliderControlWidget extends StatefulWidget {
  const SliderControlWidget({super.key});

  @override
  _SliderControlWidgetState createState() => _SliderControlWidgetState();
}

class _SliderControlWidgetState extends State<SliderControlWidget> {
  // Variables controlled by sliders
  int maxLines = 2;
  double itemWidth = 57.0;
  int itemCount = 13;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slider Control Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel with Sliders
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MaxLines Slider
                    Text('Max Lines: ${maxLines.round()}'),
                    Slider(
                      value: maxLines.toDouble(),
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: maxLines.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          maxLines = value.toInt();
                        });
                      },
                    ),

                    // Item Width Slider
                    Text('Item Width: ${itemWidth.round()}px'),
                    Slider(
                      value: itemWidth,
                      min: 30.0,
                      max: 300.0,
                      divisions: 20,
                      label: itemWidth.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          itemWidth = value;
                        });
                      },
                    ),

                    // Spacing Slider
                    Text('ItemCount: ${itemCount.round()}'),
                    Slider(
                      value: itemCount.toDouble(),
                      min: 0.0,
                      max: 50.0,
                      divisions: 50,
                      label: itemCount.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          itemCount = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Visual demonstration area
            Text(
              'Visual Result:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                      ),
                      child: limitedWrapWidget,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get limitedWrapWidget => LimitedWrapWidget(
        spacing: 0,
        runSpacing: 0,
        maxLines: maxLines.toInt(),
        overflowBuilder: OverflowBuilder(
          onTap: () => log('hello from limited wrap widget'),
          items: [
            OverflowBuilderItem.text(
              textBuilder: (count) => '+$count more',
              textStyle: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            OverflowBuilderItem.widget(
              child: Icon(Icons.chevron_right),
            ),
          ],
          style: OverflowBuilderStyle(
              border: Border.all(color: Colors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              color: Colors.amber.withAlpha(0)),
        ),
        children: List.generate(
          itemCount,
          (i) => sizedChild(
            'Item $i',
            key: ValueKey('item_$i'),
            width: itemWidth,
          ),
        ),
      );

  Widget sizedChild(String text,
      {Key? key, double width = 60, double height = 30}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(text, key: key),
        ),
      ),
    );
  }

  SliverChildDelegate getSliverChildDelegate() {
    return SliverChildBuilderDelegate(
      (context, index) =>
          sizedChild('Item $index', key: ValueKey('item_$index')),
      childCount: 10,
    );
  }
}
