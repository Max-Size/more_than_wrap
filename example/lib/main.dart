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
  double maxLines = 2.0;
  double itemWidth = 150.0;
  int itemCount = 10;

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
                    // MaxLines Slider
                    Text('Max Lines: ${maxLines.round()}'),
                    Slider(
                      value: maxLines,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: maxLines.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          maxLines = value;
                        });
                      },
                    ),

                    // Item Width Slider
                    Text('Item Width: ${itemWidth.round()}px'),
                    Slider(
                      value: itemWidth,
                      min: 100.0,
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
                  child: LimitedWrapWidget.builder(
                    spacing: 8,
                    runSpacing: 8,
                    maxLines: maxLines.toInt(),
                    overflowWidgetBuilder: (amountOfOverflowedWidgets) =>
                        DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Overflow: ${amountOfOverflowedWidgets.toString()}',
                        ),
                      ),
                    ),
                    children: List.generate(
                      itemCount,
                      (index) => Container(
                        width: itemWidth,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Item ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
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
}
