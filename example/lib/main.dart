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
      title: 'LimitedWrap Demo',
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
  State<SliderControlWidget> createState() => _SliderControlWidgetState();
}

class _SliderControlWidgetState extends State<SliderControlWidget> {
  int maxLines = 2;
  double itemWidth = 57.0;
  int itemCount = 13;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LimitedWrap Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Lines: $maxLines'),
                    Slider(
                      value: maxLines.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: maxLines.toString(),
                      onChanged: (value) {
                        setState(() => maxLines = value.toInt());
                      },
                    ),
                    Text('Item Width: ${itemWidth.round()}px'),
                    Slider(
                      value: itemWidth,
                      min: 30,
                      max: 300,
                      divisions: 20,
                      label: itemWidth.round().toString(),
                      onChanged: (value) {
                        setState(() => itemWidth = value);
                      },
                    ),
                    Text('ItemCount: $itemCount'),
                    Slider(
                      value: itemCount.toDouble(),
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: itemCount.toString(),
                      onChanged: (value) {
                        setState(() => itemCount = value.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: LimitedWrapWidget(
                        spacing: 0,
                        runSpacing: 0,
                        maxLines: maxLines,
                        overflowWidgetBuilder: (context, count) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '+$count more',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
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

  Widget sizedChild(
    String text, {
    Key? key,
    double width = 60,
    double height = 30,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: Text(text, key: key)),
      ),
    );
  }
}
