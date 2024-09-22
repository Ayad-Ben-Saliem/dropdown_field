import 'package:dropdown_field/dropdown_field.dart';
import 'package:dropdown_field_example/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide DropdownMenuItem;

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DropdownField Example'), centerTitle: true),
      body: const Row(
        children: [
          Expanded(child: UsersView(users: users)),
          VerticalDivider(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.all(100),
                child: UsersField(users: users, multiselect: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum ViewType {
  list,
  table,
  tree,
  grid;

  String get readableStr => _capitalize(toString().split('.').last);

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class UsersView extends StatefulWidget {
  final Iterable<User> users;
  final Iterable<User> initialSelected;
  final void Function(User)? onTap;
  final ViewType viewType;
  final void Function(Iterable<User>)? onSelectChanged;

  const UsersView({
    super.key,
    required this.users,
    this.initialSelected = const [],
    this.onTap,
    this.onSelectChanged,
    this.viewType = ViewType.list,
  });

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final selected = <User>[];
  var searchText = '';
  late ViewType viewType;

  @override
  void initState() {
    super.initState();

    selected.addAll(widget.initialSelected);
    viewType = widget.viewType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 128,
              child: DropdownField(
                multiselect: false,
                items: ViewType.values,
                hint: const Text('View Type'),
                childBuilder: (_, views, selected) {
                  final view = selected.isNotEmpty ? views.elementAt(selected.first) : null;
                  return Text(view?.readableStr ?? '');
                },
                itemBuilder: (_, view, index, selected) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(view.readableStr),
                  );
                },
                onChanged: (selected) {
                  if (selected.isNotEmpty) {
                    setState(() => viewType = ViewType.values[selected.first]);
                  }
                },
              ),
            ),
            Flexible(child: SearchBar(onChanged: (txt) => setState(() => searchText = txt))),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Builder(
            builder: (context) {
              final filteredUsers = filter(widget.users, searchText);
              switch (viewType) {
                case ViewType.list:
                  return listView(filteredUsers);
                case ViewType.table:
                  return tableView(filteredUsers);
                case ViewType.grid:
                  return gridView(filteredUsers);
                case ViewType.tree:
                  return const Center(child: Text('Tree View Not Supported'));
              }
            },
          ),
        ),
      ],
    );
  }

  Iterable<User> filter(Iterable<User> users, String searchText) {
    return users.where((user) {
      return user.firstName.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
  }

  Widget listView(Iterable<User> users) {
    return ListView(
      children: [
        for (final user in filter(widget.users, searchText))
          ListTile(
            selected: selected.contains(user),
            selectedColor: Colors.red,
            title: Text(user.fullName),
            subtitle: Text(user.email),
            onTap: () {
              widget.onTap?.call(user);
              setState(() {
                if (selected.contains(user)) {
                  selected.remove(user);
                } else {
                  selected.add(user);
                }
                widget.onSelectChanged?.call(selected);
              });
            },
          ),
      ],
    );
  }

  Widget tableView(Iterable<User> users) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('First Name')),
        DataColumn(label: Text('Last Name')),
        DataColumn(label: Text('E-mail')),
      ],
      rows: [
        for (final user in users)
          DataRow(
            cells: [
              DataCell(Text(user.firstName)),
              DataCell(Text(user.lastName ?? '')),
              DataCell(Text(user.email)),
            ],
          ),
      ],
    );
  }

  Widget gridView(Iterable<User> users) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth ~/ 128;

      return GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, // Number of columns
          crossAxisSpacing: 4, // Spacing between columns
          mainAxisSpacing: 4, // Spacing between rows
          childAspectRatio: 1, // Ratio of width to height for each tile
        ),
        children: [
          for (final user in users)
            Card(
              color: selected.contains(user) ? colorScheme.primary : null,
              child: DefaultTextStyle(
                style: TextStyle(color: selected.contains(user) ? colorScheme.onPrimary : colorScheme.onSurface),
                child: InkWell(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(user.fullName),
                      Text(user.email),
                    ],
                  ),
                  onTap: () {
                    widget.onTap?.call(user);
                    setState(() {
                      if (selected.contains(user)) {
                        selected.remove(user);
                      } else {
                        selected.add(user);
                      }
                      widget.onSelectChanged?.call(selected);
                    });
                  },
                ),
              ),
            ),
        ],
      );
    });
  }
}

class UsersField extends StatefulWidget {
  final Iterable<User> users;
  final Iterable<User> initialSelected;
  final bool multiselect;
  final void Function(Iterable<User> selectedUsers)? onChange;

  const UsersField({
    super.key,
    required this.users,
    this.multiselect = true,
    this.initialSelected = const [],
    this.onChange,
  });

  bool get singleSelect => !multiselect;

  @override
  State<UsersField> createState() => _UsersFieldState();
}

class _UsersFieldState extends State<UsersField> {
  var selected = <User>[];
  late UsersView usersView;

  @override
  void initState() {
    super.initState();

    selected.addAll(widget.initialSelected);

    usersView = UsersView(
      users: widget.users,
      initialSelected: selected,
      onSelectChanged: (selected) {
        setState(() {
          this.selected = selected.toList();
          widget.onChange?.call(selected);
          if (widget.singleSelect) Navigator.pop(context);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownField(
      refreshable: false,
      dropdownMenuItemsFocusColor: Colors.transparent,
      dropdownMenuItemsHoverColor: Colors.transparent,
      itemConstraints: const BoxConstraints(maxHeight: 256),
      multiselect: widget.multiselect,
      items: [usersView],
      initialSelected: [if (selected.isNotEmpty) 0],
      hint: const Text('Selected Users'),
      decoration: InputDecoration(
        labelText: 'Label Test',
        hintText: 'Hint',
        hintFadeDuration: const Duration(seconds: 5),
        contentPadding: EdgeInsets.zero,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      isExpanded: true,
      childBuilder: (context, _, __) {
        return Text(
          '$selected'.replaceAll('[', '').replaceAll(']', ''),
          maxLines: 1,
        );
      },
      itemBuilder: (context, _, __, ___) => usersView,
    );
  }
}

void debug(Object? obj) {
  if (kDebugMode) print(obj);
}
