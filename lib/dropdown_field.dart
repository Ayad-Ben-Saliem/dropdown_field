import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// We set dynamic instead of T because it causes an exception
typedef ChildBuilder<T> = Widget Function(BuildContext context, Iterable<int> indexes, /* Iterable<T> */ Iterable values);
typedef ListBuilder<T> = Widget Function(BuildContext context, int index, /* T */ dynamic value);
typedef OnSelectCallback<T> = void Function(int index, /* T */ dynamic value);
typedef OnSelectedChangedCallback<T> = void Function(Iterable<int> index, /* Iterable<T> */ Iterable value);

class StateChanger {
  bool _state;
  Function(bool)? _onChange;

  StateChanger([bool state = false]) : _state = state;

  bool get state => _state;

  set state(bool newState) {
    if (newState != state) {
      _state = newState;
      _onChange?.call(_state);
    }
  }

  void change() => state = !_state;

  @override
  String toString() => '$runtimeType @ $hashCode';
}

class DropdownField<T> extends StatefulWidget {
  final Iterable<T>? values;
  final Iterable<int>? initialIndexes;
  final ChildBuilder<T> builder;
  final ListBuilder<T>? listBuilder;
  final OnSelectCallback<T>? onSelect;
  final OnSelectedChangedCallback<T>? onSelectedChanged;
  final Widget Function(BuildContext context)? overlayBuilder;
  final StateChanger overlayStateChanger;
  final Size? overlaySize;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool openDropdownOnTap;
  final bool openDropdownOnFocus;
  final bool materialize;

  const DropdownField({
    super.key,
    this.values,
    this.initialIndexes,
    required this.builder,
    this.listBuilder,
    this.onSelect,
    this.onSelectedChanged,
    this.overlayBuilder,
    this.overlaySize,
    required this.overlayStateChanger,
    this.focusNode,
    this.onTap,
    this.openDropdownOnTap = true,
    this.openDropdownOnFocus = true,
    this.materialize = true,
  })  : assert(listBuilder != null || overlayBuilder != null),
        assert(listBuilder == null || overlayBuilder == null),
        assert(listBuilder == null && values == null || listBuilder != null && values != null);

  @override
  DropdownFieldState<T> createState() => DropdownFieldState<T>();
}

class DropdownFieldState<T> extends State<DropdownField> {
  final selectedIndexes = <int>{};

  OverlayEntry? _overlayEntry;

  late Widget Function(BuildContext context) overlayBuilder;

  final _layerLink = LayerLink();

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    selectedIndexes.addAll(widget.initialIndexes ?? []);

    overlayBuilder = _getOverlayBuilder;

    widget.overlayStateChanger._onChange = _onOverlayStateChanged;
    focusNode = widget.focusNode ?? FocusNode();
    focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant DropdownField oldWidget) {
    widget.overlayStateChanger._onChange = oldWidget.overlayStateChanger._onChange;

    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? focusNode).removeListener(_handleFocusChanged);
      (widget.focusNode ?? focusNode).addListener(_handleFocusChanged);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.materialize
          ? InkWell(
              focusNode: focusNode,
              onTap: _defaultOnTap,
              child: widget.builder(context, selectedIndexes, selectedValues),
            )
          : GestureDetector(
              onTap: _defaultOnTap,
              child: Focus(
                focusNode: focusNode,
                child: widget.builder(context, selectedIndexes, selectedValues),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    SchedulerBinding.instance.addPostFrameCallback((_) => _overlayEntry?.dispose());
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    final sizedBox = context.findRenderObject() as RenderBox;

    var dy = sizedBox.size.height + 4;

    final child = widget.materialize ? Material(elevation: 4.0, child: overlayBuilder(context)) : overlayBuilder(context);

    final pos = Positioned(
      width: sizedBox.size.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // TODO: determine the height of the child
          // final position = sizedBox.localToGlobal(Offset.zero);
          // final size = MediaQuery.of(context).size;
          // if (position.dy > size.height / 2) dy = -constraints.maxHeight - 4;
          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, dy),
            child: child,
          );
        },
      ),
    );

    return OverlayEntry(builder: (_) => pos);
  }

  void _onOverlayStateChanged(bool state) {
    if (state) {
      _overlayEntry ??= _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
    }
  }

  void _handleFocusChanged() {
    if (widget.openDropdownOnFocus) widget.overlayStateChanger.state = focusNode.hasFocus;
  }

  Widget _getOverlayBuilder(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _width, maxHeight: _height),
      child: Builder(
        builder: (_) {
          if (widget.overlayBuilder != null) {
            return SingleChildScrollView(child: widget.overlayBuilder!(context));
          }

          return ListView.separated(
            itemBuilder: (context, index) {
              final value = widget.values!.elementAt(index);
              return _defaultListTile(index, value);
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: widget.values!.length,
          );
        },
      ),
    );
  }

  Widget _defaultListTile(int index, T? value) {
    void onTap() {
      setState(() {
        selectedIndexes.contains(index) ? selectedIndexes.remove(index) : selectedIndexes.add(index);
      });
      widget.onSelectedChanged?.call(Set.from(selectedIndexes), selectedValues);
      widget.onSelect!(index, value);
    }

    return widget.materialize
        ? ListTile(
            onTap: onTap,
            title: widget.listBuilder!(context, index, value),
          )
        : GestureDetector(
            onTap: onTap,
            child: widget.listBuilder!(context, index, value),
          );
  }

  Iterable<T> get selectedValues => <T>[for (final index in selectedIndexes) widget.values?.elementAt(index)];

  double get _defaultWidth => 100;

  double get _defaultHeight => MediaQuery.of(context).size.height / 2;

  double get _width => widget.overlaySize?.width ?? _defaultWidth;

  double get _height => widget.overlaySize?.height ?? _defaultHeight;

  void _defaultOnTap() {
    widget.onTap?.call();
    if (widget.openDropdownOnTap) {
      if (focusNode.hasFocus) {
        widget.overlayStateChanger.change();
      } else if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    }
  }
}
