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
      home: SliderControlWidget(),
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
  double itemWidth = 150.0;
  int itemCount = 10;
  bool useBuilder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slider Control Example'),
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
                    // Switch to toggle between implementations
                    SwitchListTile(
                      title: Text('Use LimitedWrapWidget.builder'),
                      value: useBuilder,
                      onChanged: (value) {
                        setState(() {
                          useBuilder = value;
                        });
                      },
                    ),
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

            SizedBox(height: 8),

            // Visual demonstration area
            Text(
              'Visual Result:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),

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
                    child: SizedBox(
                      width: 200,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          log('constraints: $constraints');
                          if (useBuilder) {
                            return LimitedWrapWidget.builder(
                              spacing: 0,
                              runSpacing: 0,
                              maxLines: maxLines.toInt(),
                              overflowWidgetBuilder: (count) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  '+${count ?? 0} more',
                                  style: const TextStyle(fontSize: 14, color: Colors.red),
                                ),
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
                          } else {
                            return LimitedWrapWidget(
                              spacing: 0,
                              runSpacing: 0,
                              maxLines: maxLines.toInt(),
                              overflowBuilderStyle: OverflowBuilderStyle(
                                textBuilder: (count) => '+$count more',
                                textStyle: const TextStyle(fontSize: 14, color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          }
                        },
                      ),
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

  Widget sizedChild(String text,
      {Key? key, double width = 60, double height = 30}) {
    return SizedBox(
      width: width,
      height: height,
      child: Text(text, key: key),
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
