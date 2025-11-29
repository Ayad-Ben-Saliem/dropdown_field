import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manassa_dropdown_field/manassa_dropdown_field.dart';

void main() {
  testWidgets('DropdownField with empty items does not crash on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownField<String>(
            items: const [],
            childBuilder: (context, items, selected) => const Text('Select'),
            itemBuilder: (context, item, index, isSelected) => Text(item),
            onChanged: (values) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the dropdown
    final dropdownFinder = find.byType(DropdownField<String>);
    expect(dropdownFinder, findsOneWidget);

    // Tap the dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
  });
}
