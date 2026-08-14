import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      home: const IntFieldControlWidget(),
    );
  }
}

class IntFieldControlWidget extends StatefulWidget {
  const IntFieldControlWidget({super.key});

  @override
  State<IntFieldControlWidget> createState() => _IntFieldControlWidgetState();
}

class _IntFieldControlWidgetState extends State<IntFieldControlWidget> {
  late final TextEditingController _maxLinesController;
  late final TextEditingController _itemWidthController;
  late final TextEditingController _itemCountController;

  int maxLines = 2;
  int itemWidth = 57;
  int itemCount = 13;

  @override
  void initState() {
    super.initState();
    _maxLinesController = TextEditingController(text: '$maxLines');
    _itemWidthController = TextEditingController(text: '$itemWidth');
    _itemCountController = TextEditingController(text: '$itemCount');
  }

  @override
  void dispose() {
    _maxLinesController.dispose();
    _itemWidthController.dispose();
    _itemCountController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _IntTextField(
                      label: 'Max Lines',
                      controller: _maxLinesController,
                      onChanged: (value) => setState(() => maxLines = value),
                    ),
                    const SizedBox(height: 12),
                    _IntTextField(
                      label: 'Item Width (px)',
                      controller: _itemWidthController,
                      onChanged: (value) => setState(() => itemWidth = value),
                    ),
                    const SizedBox(height: 12),
                    _IntTextField(
                      label: 'Item Count',
                      controller: _itemCountController,
                      onChanged: (value) => setState(() => itemCount = value),
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
                            width: itemWidth.toDouble(),
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

class _IntTextField extends StatelessWidget {
  const _IntTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const _PositiveIntFormatter(),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) {
        if (value.isEmpty) return;
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) onChanged(parsed);
      },
    );
  }
}

class _PositiveIntFormatter extends TextInputFormatter {
  const _PositiveIntFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value <= 0) return oldValue;
    return newValue;
  }
}
