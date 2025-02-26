# manassa_dropdown_field
A Flutter package providing a highly customizable dropdown field with **multi-select** functionality, search/filtering, and custom item builders.


## Description
The `manassa_dropdown_field` package offers a flexible and powerful way to create dropdown fields in your Flutter applications.  Unlike the standard Flutter dropdown widgets, this package allows for:

* **Multi-selection:**  Select multiple items from the dropdown list.
* **Customizable Styling:** Control the appearance of the dropdown, including colors, fonts, borders, and item shapes.
* **Search/Filtering:**  Quickly find items in long lists using the built-in search functionality.
* **Custom Item Builders:**  Build entirely custom widgets for the items displayed in the dropdown.

## Features

* Multi-select functionality (`multiselect: true`).
* Customizable dropdown appearance.
* Search/filtering within the dropdown.
* Support for custom item widgets.
* Clearable selection.
* Easy to use and integrate.

## Usage
```dart
  final List<String> selectedLanguages = <String>[];
  final List<String> languages = [
    "Dart",
    "JavaScript",
    "Python",
    "Java",
    "C++",
    "C#",
    "Kotlin",
    "Swift",
    "Go",
    "Ruby",
  ];

DropdownField<String>(
  height: 40, // Height of the input field
  itemConstraints: const BoxConstraints(maxHeight: 40), // Max height of each item
  menuMaxHeight: 250, // Max height of the dropdown menu
  menuMinHeight: 40, // Min height of the dropdown menu
  initialSelected: [0, 1], // initial selected items
  multiselect: true, // Enables multi-selection.
  refreshDropdownMenuItemsOnChange: true, // Rebuilds dropdown items when the selected items change.
  items: languages, // A list of strings representing the available languages.
  onChanged: (Iterable<int> indices) { // Callback function triggered when the selected items change. `indices` is an Iterable<int> containing the indices of the selected items.
    selectedLanguages.clear(); // Clears the list of selected languages before updating it. `selectedLanguages` will store the actual selected language strings.
    for (int index in indices) { 
      selectedLanguages.add(languages[index]); 
    }
  },
  decoration: const InputDecoration(
                labelText: 'Hello, world',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.code),
              ),
  childBuilder: ( // Builds the widget displayed *before* the dropdown opens.
    BuildContext context,
    Iterable<String> items, 
    Iterable<int> selected, 
  ) {
    final String selectedText = selectedLanguages.join(", "); 
    return Row(
      children: [
        const Icon(Icons.keyboard_arrow_down),
        Text(selectedText.isEmpty ? "Select Languages" : selectedText), 
      ],
    );
  },
  itemBuilder: ( // Builds each individual item *in* the dropdown list.
    BuildContext context,
    String item,
    int index, 
    bool isSelected, 
  ) {
    return Text(
      item,
      style: TextStyle(
        color: isSelected ? Colors.blue : Colors.black, // Sets the text color to blue if selected, black otherwise.
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Sets the text to bold if selected.
      ),
    );
  },
)
```

![Multi Select Programming Languages](assets/manassa_dropdown_field.gif)
