import 'package:dropdown_field/dropdown_field.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final stateChanger = StateChanger();
    final stateChanger2 = StateChanger();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 255),
          child: Column(
            children: [
              const TextField(),
              DropdownField<String>(
                overlayStateChanger: stateChanger,
                builder: (context, indexes, values) => Text('Test ${values ?? '#'}'),
                values: const ['1', '2', '3'],
                listBuilder: (context, index, value) => Text(value),
                onSelect: (index, value) {},
                materialize: false,
              ),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              const TextField(),
              DropdownField(
                overlayStateChanger: stateChanger2,
                builder: (context, indexes, values) => Text('Test $values'),
                overlayBuilder: (context) {
                  return const Column(
                    children: [
                      Text('1'),
                      Text('2'),
                      Text('3'),
                    ],
                  );
                },
                onTap: () {},
                openDropdownOnTap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
