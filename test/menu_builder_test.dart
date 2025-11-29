import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manassa_dropdown_field/manassa_dropdown_field.dart';

void main() {
  testWidgets('DropdownField uses menuBuilder when provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownField<String>(
            items: const ['A', 'B'],
            childBuilder: (context, items, selected) => const Text('Select'),
            itemBuilder: (context, item, index, isSelected) => Text(item),
            onChanged: (values) {},
            menuBuilder: (context, items) {
              return Container(
                key: const Key('custom_menu'),
                height: 100,
                color: Colors.red,
                child: Column(
                  children: items.map((e) => Text(e)).toList(),
                ),
              );
            },
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

    // Verify custom menu is shown
    expect(find.byKey(const Key('custom_menu')), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('DropdownField uses default menu when menuBuilder returns null',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownField<String>(
            items: const ['A', 'B'],
            childBuilder: (context, items, selected) => const Text('Select'),
            itemBuilder: (context, item, index, isSelected) => Text(item),
            onChanged: (values) {},
            menuBuilder: (context, items) =>
                null, // Return null to use default menu
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

    // Verify default menu is shown (ListView inside Scrollbar)
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
