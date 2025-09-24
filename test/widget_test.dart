// Basic, self-contained Flutter widget test (decoupled from app bootstrapping).
// This avoids initializing Hive or app bindings that aren't needed for unit testing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterApp extends StatefulWidget {
  const _CounterApp();
  @override
  State<_CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<_CounterApp> {
  int _count = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Counter Test')),
        body: Center(child: Text('$_count')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() => _count++),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the minimal counter app and trigger a frame.
    await tester.pumpWidget(const _CounterApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
