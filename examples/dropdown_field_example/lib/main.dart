import 'package:dropdown_field/dropdown_field.dart';
import 'package:dropdown_field_example/user_model.dart';
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

    final users = [
      User(firstName: 'Mohammed', email: 'mohammed@gmail.com'),
      User(firstName: 'Omar', email: 'omar@gmail.com'),
      User(firstName: 'Ali', email: 'ali@gmail.com'),
      User(firstName: 'Ayad', email: 'ayad@gmail.com'),
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 255),
          child: Column(
            children: [
              DropdownField<String>(
                overlayStateChanger: stateChanger,
                builder: (context, indexes, values) => Text('Test ${values ?? '#'}'),
                values: const ['1', '2', '3'],
                listBuilder: (context, index, value) => Text(value),
                onSelect: (index, value) {},
                materialize: false,
              ),
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
                openDropdownOnFocus: false,
              ),
              DropdownField<User>(
                overlayStateChanger: StateChanger(),
                builder: (context, indexes, values) => SizedBox(
                  width: 250,
                  child: Text('All Users ${values ?? '#'}'),
                ),
                values: users,
                selectedColor: Colors.amber,
                selectedTileColor: Theme.of(context).colorScheme.primary,
                listBuilder: (context, index, value) => Text('$value'),
                onSelectedChanged: (indexes, values) {
                  print(indexes);
                  print(values);
                },
                onSelect: (index, value) {},
              ),
              Builder(
                builder: (context) {
                  var selectedIndexes = <int>{};
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return DropdownField<User>(
                        overlayStateChanger: StateChanger(),
                        builder: (context, indexes, values) => SizedBox(
                          width: 250,
                          child: Text('All Users ${values ?? '#'}'),
                        ),
                        overlayBuilder: (_) {
                          return Column(
                            children: [
                              for (var index = 0; index < users.length; index++)
                                ListTile(
                                  selected: selectedIndexes.contains(index),
                                  selectedTileColor: Theme.of(context).colorScheme.primary,
                                  selectedColor: Theme.of(context).colorScheme.onPrimary,
                                  title: Text(users[index].firstName),
                                  onTap: () {
                                    setState(() {
                                      if (selectedIndexes.contains(index)) {
                                        selectedIndexes.remove(index);
                                      } else {
                                        selectedIndexes.add(index);
                                      }
                                    });
                                  },
                                ),
                            ],
                          );
                        },
                        onSelect: (index, value) {},
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
