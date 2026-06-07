import 'package:drug/features/inventory/presentation/widgets/inventory_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('typing in the search bar calls onChanged after debounce',
      (tester) async {
    String captured = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventorySearchBar(
            initialValue: '',
            onChanged: (v) => captured = v,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'aspirin');
    expect(captured, isEmpty, reason: 'should not fire during debounce window');

    await tester.pump(const Duration(milliseconds: 260));
    expect(captured, 'aspirin');
  });

  testWidgets('clearing the search emits empty string and hides suffix icon',
      (tester) async {
    String captured = 'initial';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventorySearchBar(
            initialValue: 'aspirin',
            onChanged: (v) => captured = v,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.byIcon(Icons.close), findsNothing);
    expect(captured, '');
    expect(
      (tester.widget<TextField>(find.byType(TextField))).controller!.text,
      isEmpty,
    );
  });

  testWidgets('initialValue change updates the controller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventorySearchBar(
            initialValue: '',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      (tester.widget<TextField>(find.byType(TextField))).controller!.text,
      isEmpty,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventorySearchBar(
            initialValue: 'ibuprofen',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      (tester.widget<TextField>(find.byType(TextField))).controller!.text,
      'ibuprofen',
    );
  });
}
