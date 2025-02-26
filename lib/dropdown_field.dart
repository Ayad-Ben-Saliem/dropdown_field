// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const Duration kDropdownMenuDuration = Duration(milliseconds: 300);
const double kFieldHeight = kMinInteractiveDimension;
const double kMenuItemHeight = kMinInteractiveDimension;
const double kDenseButtonHeight = 24.0;
const double kMenuItemMinHeight = kDenseButtonHeight;
const BoxConstraints kMenuItemConstraints = BoxConstraints(minHeight: kDenseButtonHeight);

/// A builder to customize dropdown buttons.
///
/// Used by [DropdownField.selectedItemBuilder].
typedef DropdownFieldBuilder = List<Widget> Function(BuildContext context);

typedef DropdownChildBuilder<T> = Widget? Function(BuildContext context, Iterable<T> items, Iterable<int> selected);

typedef DropdownItemBuilder<T> = Widget Function(BuildContext context, T item, int index, bool isSelected);

//Add onTap Callback function which will return the index of the item selected
typedef OnTapCallback = void Function(int index);

class DropdownMenuPainter extends CustomPainter {
  DropdownMenuPainter({
    this.color,
    this.elevation,
    this.selectedIndex = const [],
    this.borderRadius,
    required this.resize,
    required this.getSelectedItemsOffset,
  })  : _painter = BoxDecoration(
          // If you add an image here, you must provide a real
          // configuration in the paint() function and you must provide some sort
          // of onChanged callback here.
          color: color,
          borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(2.0)),
          boxShadow: kElevationToShadow[elevation],
        ).createBoxPainter(),
        super(repaint: resize);

  final Color? color;
  final int? elevation;
  final Iterable<int> selectedIndex;
  final BorderRadius? borderRadius;
  final Animation<double> resize;
  final ValueGetter<Iterable<double>> getSelectedItemsOffset;
  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    final selectedItemsOffset = getSelectedItemsOffset();
    for (final selectedItemOffset in selectedItemsOffset) {
      final top = Tween<double>(
        begin: clampDouble(selectedItemOffset, 0.0, math.max(size.height - kMenuItemHeight, 0.0)),
        end: 0.0,
      );

      final Tween<double> bottom = Tween<double>(
        begin: clampDouble(top.begin! + kMenuItemHeight, math.min(kMenuItemHeight, size.height), size.height),
        end: size.height,
      );

      final Rect rect = Rect.fromLTRB(0.0, top.evaluate(resize), size.width, bottom.evaluate(resize));

      _painter.paint(canvas, rect.topLeft, ImageConfiguration(size: rect.size));
    }
  }

  @override
  bool shouldRepaint(DropdownMenuPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.elevation != elevation || oldDelegate.selectedIndex != selectedIndex || oldDelegate.borderRadius != borderRadius || oldDelegate.resize != resize;
  }
}

// The widget that is the button wrapping the menu items.
class DropdownMenuItemButton<T> extends StatefulWidget {
  const DropdownMenuItemButton({
    super.key,
    this.padding,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    required this.itemIndex,
    required this.focusColor,
    required this.hoverColor,
    required this.enableFeedback,
    required this.scrollController,
  });

  final DropdownRoute<T> route;
  final ScrollController scrollController;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final int itemIndex;
  final Color? focusColor;
  final Color? hoverColor;
  final bool enableFeedback;

  @override
  DropdownMenuItemButtonState<T> createState() => DropdownMenuItemButtonState<T>();
}

class DropdownMenuItemButtonState<T> extends State<DropdownMenuItemButton<T>> {
  void _handleFocusChange(bool focused) {
    final bool inTraditionalMode = switch (FocusManager.instance.highlightMode) {
      FocusHighlightMode.touch => false,
      FocusHighlightMode.traditional => true,
    };

    if (focused && inTraditionalMode) {
      final menuLimit = widget.route.getMenuLimit(
        widget.buttonRect,
        widget.constraints.maxHeight,
        widget.itemIndex,
      );
      widget.scrollController.animateTo(
        menuLimit.scrollOffset,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 100),
      );
    }
  }

  void _handleOnTap() {
    final DropdownMenuItem<T> dropdownMenuItem = widget.route.items[widget.itemIndex].item!;

    dropdownMenuItem.onTap?.call(widget.itemIndex);

    Navigator.pop(context, DropdownRouteResult<T>(dropdownMenuItem.index, dropdownMenuItem.value));
  }

  static const Map<ShortcutActivator, Intent> _webShortcuts = <ShortcutActivator, Intent>{
    // On the web, up/down don't change focus, *except* in a <select>
    // element, which is what a dropdown emulates.
    SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  };

  @override
  Widget build(BuildContext context) {
    final DropdownMenuItem<T> dropdownMenuItem = widget.route.items[widget.itemIndex].item!;
    final CurvedAnimation opacity;
    final double unit = 0.5 / (widget.route.items.length + 1.5);
    if (widget.route.selectedIndexes.contains(widget.itemIndex)) {
      opacity = CurvedAnimation(parent: widget.route.animation!, curve: const Threshold(0.0));
    } else {
      final double start = clampDouble(0.5 + (widget.itemIndex + 1) * unit, 0.0, 1.0);
      final double end = clampDouble(start + 1.5 * unit, 0.0, 1.0);
      opacity = CurvedAnimation(parent: widget.route.animation!, curve: Interval(start, end));
    }

    Widget child = widget.route.items[widget.itemIndex];

    child = Container(padding: widget.padding, height: widget.route.itemHeight, child: child);

    child = ConstrainedBox(constraints: widget.route.itemConstraints, child: child);

    // An [InkWell] is added to the item only if it is enabled
    if (dropdownMenuItem.enabled) {
      child = InkWell(
        autofocus: widget.route.selectedIndexes.contains(widget.itemIndex),
        focusColor: widget.focusColor ?? Theme.of(context).focusColor,
        hoverColor: widget.hoverColor ?? Theme.of(context).hoverColor,
        enableFeedback: widget.enableFeedback,
        onTap: _handleOnTap,
        onFocusChange: _handleFocusChange,
        child: child,
      );
    }
    child = FadeTransition(opacity: opacity, child: child);
    if (kIsWeb && dropdownMenuItem.enabled) {
      child = Shortcuts(shortcuts: _webShortcuts, child: child);
    }
    return child;
  }
}

class DropdownMenu<T> extends StatefulWidget {
  const DropdownMenu({
    super.key,
    this.padding,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    required this.dropdownColor,
    required this.itemsFocusColor,
    required this.itemsHoverColor,
    required this.borderRadius,
    required this.enableFeedback,
    required this.scrollController,
  });

  final DropdownRoute<T> route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final Color? dropdownColor;
  final Color? itemsFocusColor;
  final Color? itemsHoverColor;
  final bool enableFeedback;
  final BorderRadius? borderRadius;
  final ScrollController scrollController;

  @override
  DropdownMenuState<T> createState() => DropdownMenuState<T>();
}

class DropdownMenuState<T> extends State<DropdownMenu<T>> {
  late CurvedAnimation _fadeOpacity;
  late CurvedAnimation _resize;

  @override
  void initState() {
    super.initState();
    // We need to hold these animations as state because of their curve
    // direction. When the route's animation reverses, if we were to recreate
    // the CurvedAnimation objects in build, we'd lose
    // CurvedAnimation._curveDirection.
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0),
    );
    _resize = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Threshold(0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The menu is shown in three stages (unit timing in brackets):
    // [0s - 0.25s] - Fade in a rect-sized menu container with the selected item.
    // [0.25s - 0.5s] - Grow the otherwise empty menu container from the center
    //   until it's big enough for as many items as we're going to show.
    // [0.5s - 1.0s] Fade in the remaining visible items from top to bottom.
    //
    // When the menu is dismissed we just fade the entire thing out
    // in the first 0.25s.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final DropdownRoute<T> route = widget.route;
    final List<Widget> children = <Widget>[
      for (int itemIndex = 0; itemIndex < route.items.length; ++itemIndex)
        DropdownMenuItemButton<T>(
          route: widget.route,
          padding: widget.padding,
          buttonRect: widget.buttonRect,
          constraints: widget.constraints,
          itemIndex: itemIndex,
          focusColor: widget.itemsFocusColor,
          hoverColor: widget.itemsHoverColor,
          enableFeedback: widget.enableFeedback,
          scrollController: widget.scrollController,
        ),
    ];

    return FadeTransition(
      opacity: _fadeOpacity,
      child: CustomPaint(
        painter: DropdownMenuPainter(
          color: widget.dropdownColor ?? Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndexes,
          resize: _resize,
          borderRadius: widget.borderRadius,
          // This offset is passed as a callback, not a value, because it must
          // be retrieved at paint time (after layout), not at build time.
          getSelectedItemsOffset: () => route.getItemsOffset(route.selectedIndexes),
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: localizations.popupMenuLabel,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
            child: Material(
              type: MaterialType.transparency,
              textStyle: route.style,
              child: ScrollConfiguration(
                // Dropdown menus should never overscroll or display an overscroll indicator.
                // Scrollbars are built-in below.
                // Platform must use Theme and ScrollPhysics must be Clamping.
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                  overscroll: false,
                  physics: const ClampingScrollPhysics(),
                  platform: Theme.of(context).platform,
                ),
                child: PrimaryScrollController(
                  controller: widget.scrollController,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      // Ensure this always inherits the PrimaryScrollController
                      primary: true,
                      padding: kMaterialListPadding,
                      shrinkWrap: true,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DropdownMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  DropdownMenuRouteLayout({
    required this.buttonRect,
    required this.route,
    required this.textDirection,
  });

  final Rect buttonRect;
  final DropdownRoute<T> route;
  final TextDirection? textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The maximum height of a simple menu should be one or more rows less than
    // the view height. This ensures a tappable area outside of the simple menu
    // with which to dismiss the menu.
    //   -- https://material.io/design/components/menus.html#usage
    double maxHeight = math.max(0.0, constraints.maxHeight - 2 * kMenuItemHeight);
    if (route.menuMaxHeight != null && route.menuMaxHeight! <= maxHeight) {
      maxHeight = route.menuMaxHeight!;
    }
    // The width of a menu should be at most the view width. This ensures that
    // the menu does not extend past the left and right edges of the screen.
    final double width = math.min(constraints.maxWidth, buttonRect.width);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: route.menuMinHeight ?? kMenuItemMinHeight,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final selectedIndexes = List<int>.from(route.selectedIndexes);
    if (selectedIndexes.isEmpty) selectedIndexes.add(0);
    final menuLimits = route.getMenuLimits(buttonRect, size.height, selectedIndexes);

    // Get the smallest top
    var menuLimit = menuLimits.first;
    for (final limit in menuLimits) {
      if (menuLimit.top > limit.top) menuLimit = limit;
    }

    assert(() {
      final container = Rect.fromLTWH(0, 0, size.width, size.height);
      if (container.intersect(buttonRect) == buttonRect) {
        // If the button was entirely on-screen, then verify
        // that the menu is also on-screen.
        // If the button was a bit off-screen, then, oh well.
        assert(menuLimit.top >= 0.0);
        assert(menuLimit.top + menuLimit.height <= size.height);
      }
      return true;
    }());

    assert(textDirection != null);
    final left = switch (textDirection!) {
      TextDirection.rtl => clampDouble(buttonRect.right, 0.0, size.width) - childSize.width,
      TextDirection.ltr => clampDouble(buttonRect.left, 0.0, size.width - childSize.width),
    };

    return Offset(left, menuLimit.top);
  }

  @override
  bool shouldRelayout(DropdownMenuRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect || textDirection != oldDelegate.textDirection;
  }
}

// We box the return value so that the return value can be null. Otherwise,
// canceling the route (which returns null) would get confused with actually
// returning a real null value.
@immutable
class DropdownRouteResult<T> {
  const DropdownRouteResult(this.index, this.value);

  final T value;
  final int index;

  @override
  bool operator ==(Object other) {
    return other is DropdownRouteResult<T> && value == other.value && index == other.index;
  }

  @override
  int get hashCode => index.hashCode;
}

class MenuLimit {
  const MenuLimit(this.top, this.bottom, this.height, this.scrollOffset);

  final double top;
  final double bottom;
  final double height;
  final double scrollOffset;
}

class DropdownRoute<T> extends PopupRoute<DropdownRouteResult<T>> {
  DropdownRoute({
    required this.items,
    required this.padding,
    required this.buttonRect,
    required this.selectedIndexes,
    this.elevation = 8,
    required this.capturedThemes,
    required this.style,
    this.barrierLabel,
    this.itemHeight,
    required this.itemConstraints,
    this.dropdownColor,
    this.menuItemsFocusColor,
    this.menuItemsHoverColor,
    this.menuMinHeight = kMenuItemMinHeight,
    this.menuMaxHeight,
    required this.enableFeedback,
    this.borderRadius,
  }) : itemHeights = List<double>.filled(items.length, itemHeight ?? kMenuItemHeight);

  final List<MenuItem<T>> items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final Iterable<int> selectedIndexes;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle style;
  final double? itemHeight;
  final BoxConstraints itemConstraints;
  final Color? dropdownColor;
  final Color? menuItemsFocusColor;
  final Color? menuItemsHoverColor;
  final double? menuMinHeight;
  final double? menuMaxHeight;
  final bool enableFeedback;
  final BorderRadius? borderRadius;

  final List<double> itemHeights;

  @override
  Duration get transitionDuration => kDropdownMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return DropdownRoutePage<T>(
          route: this,
          constraints: constraints,
          items: items,
          padding: padding,
          buttonRect: buttonRect,
          selectedIndexes: selectedIndexes,
          elevation: elevation,
          capturedThemes: capturedThemes,
          style: style,
          dropdownColor: dropdownColor,
          menuItemsFocusColor: menuItemsFocusColor,
          menuItemsHoverColor: menuItemsHoverColor,
          enableFeedback: enableFeedback,
          borderRadius: borderRadius,
        );
      },
    );
  }

  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }

  Iterable<double> getItemsOffset(Iterable<int> indexes) {
    return [for (final index in indexes) getItemOffset(index)];
  }

  double getItemOffset(int index) {
    double offset = kMaterialListPadding.top;
    if (items.isNotEmpty && index > 0) {
      assert(items.length == itemHeights.length);
      offset += itemHeights.sublist(0, index).reduce((double total, double height) => total + height);
    }
    return offset;
  }

  Iterable<MenuLimit> getMenuLimits(Rect buttonRect, double availableHeight, Iterable<int> indexes) {
    return [for (final index in indexes) getMenuLimit(buttonRect, availableHeight, index)];
  }

  // Returns the vertical extent of the menu and the initial scrollOffset
  // for the ListView that contains the menu items. The vertical center of the
  // selected item is aligned with the button's vertical center, as far as
  // that's possible given availableHeight.
  MenuLimit getMenuLimit(Rect buttonRect, double availableHeight, int index) {
    double computedMaxHeight = availableHeight - 2.0 * kMenuItemHeight;
    if (menuMaxHeight != null) {
      computedMaxHeight = math.min(computedMaxHeight, menuMaxHeight!);
    }
    final double buttonTop = buttonRect.top;
    final double buttonBottom = math.min(buttonRect.bottom, availableHeight);
    final double itemOffset = getItemOffset(index);

    // If the button is placed on the bottom or top of the screen, its top or
    // bottom may be less than [_kMenuItemHeight] from the edge of the screen.
    // In this case, we want to change the menu limits to align with the top
    // or bottom edge of the button.
    final double topLimit = math.min(kMenuItemHeight, buttonTop);
    final double bottomLimit = math.max(availableHeight - kMenuItemHeight, buttonBottom);

    double menuTop = (buttonTop - itemOffset) - (itemHeights[index] - buttonRect.height) / 2.0;
    double preferredMenuHeight = kMaterialListPadding.vertical;
    if (items.isNotEmpty) {
      preferredMenuHeight += itemHeights.reduce((double total, double height) => total + height);
    }

    // If there are too many elements in the menu, we need to shrink it down
    // so it is at most the computedMaxHeight.
    final double menuHeight = math.min(computedMaxHeight, preferredMenuHeight);
    double menuBottom = menuTop + menuHeight;

    // If the computed top or bottom of the menu are outside of the range
    // specified, we need to bring them into range. If the item height is larger
    // than the button height and the button is at the very bottom or top of the
    // screen, the menu will be aligned with the bottom or top of the button
    // respectively.
    if (menuTop < topLimit) {
      menuTop = math.min(buttonTop, topLimit);
      menuBottom = menuTop + menuHeight;
    }

    if (menuBottom > bottomLimit) {
      menuBottom = math.max(buttonBottom, bottomLimit);
      menuTop = menuBottom - menuHeight;
    }

    if (menuBottom - itemHeights[index] / 2.0 < buttonBottom - buttonRect.height / 2.0) {
      menuBottom = buttonBottom - buttonRect.height / 2.0 + itemHeights[index] / 2.0;
      menuTop = menuBottom - menuHeight;
    }

    double scrollOffset = 0;
    // If all of the menu items will not fit within availableHeight then
    // compute the scroll offset that will line the selected menu item up
    // with the select item. This is only done when the menu is first
    // shown - subsequently we leave the scroll offset where the user left
    // it. This scroll offset is only accurate for fixed height menu items
    // (the default).
    if (preferredMenuHeight > computedMaxHeight) {
      // The offset should be zero if the selected item is in view at the beginning
      // of the menu. Otherwise, the scroll offset should center the item if possible.
      scrollOffset = math.max(0.0, itemOffset - (buttonTop - menuTop));
      // If the selected item's scroll offset is greater than the maximum scroll offset,
      // set it instead to the maximum allowed scroll offset.
      scrollOffset = math.min(scrollOffset, preferredMenuHeight - menuHeight);
    }

    assert((menuBottom - menuTop - menuHeight).abs() < precisionErrorTolerance);
    return MenuLimit(menuTop, menuBottom, menuHeight, scrollOffset);
  }
}

class DropdownRoutePage<T> extends StatefulWidget {
  const DropdownRoutePage({
    super.key,
    required this.route,
    required this.constraints,
    this.items,
    required this.padding,
    required this.buttonRect,
    required this.selectedIndexes,
    this.elevation = 8,
    required this.capturedThemes,
    this.style,
    required this.dropdownColor,
    required this.menuItemsFocusColor,
    required this.menuItemsHoverColor,
    required this.enableFeedback,
    this.borderRadius,
  });

  final DropdownRoute<T> route;
  final BoxConstraints constraints;
  final List<MenuItem<T>>? items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final Iterable<int> selectedIndexes;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final Color? dropdownColor;
  final Color? menuItemsFocusColor;
  final Color? menuItemsHoverColor;
  final bool enableFeedback;
  final BorderRadius? borderRadius;

  @override
  State<DropdownRoutePage<T>> createState() => DropdownRoutePageState<T>();
}

class DropdownRoutePageState<T> extends State<DropdownRoutePage<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    // Computing the initialScrollOffset now, before the items have been laid out.
    // This only works if the item heights are effectively fixed, i.e. either
    // DropdownField.itemHeight is specified or DropdownField.itemHeight is null
    // and all of the items' intrinsic heights are less than kMinInteractiveDimension.
    // Otherwise the initialScrollOffset is just a rough approximation based on
    // treating the items as if their heights were all equal to kMinInteractiveDimension.
    final menuLimits = widget.route.getMenuLimits(widget.buttonRect, widget.constraints.maxHeight, widget.selectedIndexes);
    if (menuLimits.isNotEmpty) _scrollController = ScrollController(initialScrollOffset: menuLimits.first.scrollOffset);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = DropdownMenu<T>(
      route: widget.route,
      padding: widget.padding.resolve(textDirection),
      buttonRect: widget.buttonRect,
      constraints: widget.constraints,
      dropdownColor: widget.dropdownColor,
      itemsFocusColor: widget.menuItemsFocusColor,
      itemsHoverColor: widget.menuItemsHoverColor,
      enableFeedback: widget.enableFeedback,
      borderRadius: widget.borderRadius,
      scrollController: _scrollController,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: CustomSingleChildLayout(
        delegate: DropdownMenuRouteLayout<T>(
          buttonRect: widget.buttonRect,
          route: widget.route,
          textDirection: textDirection,
        ),
        child: widget.capturedThemes.wrap(menu),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// This widget enables _DropdownRoute to look up the sizes of
// each menu item. These sizes are used to compute the offset of the selected
// item so that _DropdownRoutePage can align the vertical center of the
// selected item lines up with the vertical center of the dropdown button,
// as closely as possible.
class MenuItem<T> extends SingleChildRenderObjectWidget {
  const MenuItem({
    super.key,
    required this.onLayout,
    required this.item,
  }) : super(child: item);

  final ValueChanged<Size> onLayout;
  final DropdownMenuItem<T>? item;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class RenderMenuItem extends RenderProxyBox {
  RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout(size);
  }
}

// The container widget for a menu item created by a [DropdownButton]. It
// provides the default configuration for [DropdownMenuItem]s, as well as a
// [DropdownButton]'s hint and disabledHint widgets.
class DropdownMenuItemContainer extends StatelessWidget {
  /// Creates an item for a dropdown menu.
  ///
  /// The [child] argument is required.
  const DropdownMenuItemContainer({
    super.key,
    this.alignment = AlignmentDirectional.centerStart,
    required this.child,
  });

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// Defines how the item is positioned within the container.
  ///
  /// Defaults to [AlignmentDirectional.centerStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: kMenuItemHeight),
      alignment: alignment,
      child: child,
    );
  }
}

/// An item in a menu created by a [DropdownButton].
///
/// The type `T` is the type of the value the entry represents. All the entries
/// in a given menu must represent values with consistent types.
class DropdownMenuItem<T> extends DropdownMenuItemContainer {
  /// Creates an item for a dropdown menu.
  ///
  /// The [child] argument is required.
  const DropdownMenuItem({
    super.key,
    required this.index,
    required this.value,
    this.onTap,
    this.enabled = true,
    super.alignment,
    required super.child,
  });

  /// Called when the dropdown menu item is tapped.
  final OnTapCallback? onTap;

  /// The value to return if the user selects this menu item.
  ///
  /// Eventually returned in a call to [DropdownButton.onChanged].
  final T value;

  final int index;

  /// Whether or not a user can select this menu item.
  ///
  /// Defaults to `true`.
  final bool enabled;
}

/// A Material Design button for selecting from a list of items.
///
/// A dropdown button lets the user select from a number of items. The button
/// shows the currently selected item as well as an arrow that opens a menu for
/// selecting another item.
///
/// ## Updating to [DropdownMenu]
///
/// There is a Material 3 version of this component,
/// [DropdownMenu] that is preferred for applications that are configured
/// for Material 3 (see [ThemeData.useMaterial3]).
/// The [DropdownMenu] widget's visuals
/// are a little bit different, see the Material 3 spec at
/// <https://m3.material.io/components/menus/guidelines> for
/// more details.
///
/// The [DropdownMenu] widget's API is also slightly different.
/// To update from [DropdownField] to [DropdownMenu], you will
/// need to make the following changes:
///
/// 1. Instead of using [DropdownField.dropdownMenuItems], which
/// takes a list of [DropdownMenuItem]s, use
/// [DropdownMenu.dropdownMenuEntries], which
/// takes a list of [DropdownMenuEntry]'s.
///
/// 2. Instead of using [DropdownField.onChanged],
/// use [DropdownMenu.onSelected], which is also
/// a callback that is called when the user selects an entry.
///
/// 3. In [DropdownMenu] it is not required to track
/// the current selection in your app's state.
/// So, instead of tracking the current selection in
/// the [DropdownField.initialSelected] property, you can set the
/// [DropdownMenu.initialSelection] property to the
/// item that should be selected before there is any user action.
///
/// 4. You may also need to make changes to the styling of the
/// [DropdownMenu], see the properties in the [DropdownMenu]
/// constructor for more details.
///
/// See the sample below for an example of migrating
/// from [DropdownField] to [DropdownMenu].
///
/// ## Using [DropdownField]
/// {@youtube 560 315 https://www.youtube.com/watch?v=ZzQ_PWrFihg}
///
/// One ancestor must be a [Material] widget and typically this is
/// provided by the app's [Scaffold].
///
/// The type `T` is the type of the [initialSelected] that each dropdown item represents.
/// All the entries in a given menu must represent values with consistent types.
/// Typically, an enum is used. Each [DropdownMenuItem] in [dropdownMenuItems] must be
/// specialized with that same type argument.
///
/// The [onChanged] callback should update a state variable that defines the
/// dropdown's value. It should also call [State.setState] to rebuild the
/// dropdown with the new value.
///
///
/// {@tool dartpad}
/// This sample shows a [DropdownField] with a large arrow icon,
/// purple text style, whose value is one of "One",
/// "Two", "Three", or "Four".
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/dropdown_button.png)
///
/// ** See code in examples/api/lib/material/dropdown/dropdown_button.0.dart **
/// {@end-tool}
///
/// If the [onChanged] callback is null or the list of [dropdownMenuItems] is null
/// then the dropdown button will be disabled, i.e. its arrow will be
/// displayed in grey and it will not respond to input. A disabled button
/// will display the [disabledHint] widget if it is non-null. However, if
/// [disabledHint] is null and [hint] is non-null, the [hint] widget will
/// instead be displayed.
///
/// {@tool dartpad}
/// This sample shows how you would rewrite the above [DropdownField]
/// to use the [DropdownMenu].
///
/// ** See code in examples/api/lib/material/dropdown_menu/dropdown_menu.1.dart **
/// {@end-tool}
///
///
/// See also:
///
///  * [DropdownFormField], which integrates with the [Form] widget.
///  * [DropdownMenuItem], the class used to represent the [dropdownMenuItems].
///  * [ElevatedButton], [TextButton], ordinary buttons that trigger a single action.
///  * <https://material.io/design/components/menus.html#dropdown-menu>
class DropdownField<T> extends StatefulWidget {
  /// Creates a dropdown button.
  ///
  /// The [items] must have distinct values. If [initialSelected] isn't null then it
  /// must be equal to one of the [DropdownMenuItem] values. If [items] or
  /// [onChanged] is null, the button will be disabled, the down arrow
  /// will be greyed out.
  ///
  /// If [initialSelected] is null and the button is enabled, [hint] will be displayed
  /// if it is non-null.
  ///
  /// If [initialSelected] is null and the button is disabled, [disabledHint] will be displayed
  /// if it is non-null. If [disabledHint] is null, then [hint] will be displayed
  /// if it is non-null.
  ///
  /// The [dropdownColor] argument specifies the background color of the
  /// dropdown when it is open. If it is null, the current theme's
  /// [ThemeData.canvasColor] will be used instead.
  const DropdownField({
    super.key,
    required this.items,
    required this.childBuilder,
    required this.itemBuilder,
    this.refreshable = true,
    this.refreshDropdownMenuItemsOnChange = false,
    this.initialSelected = const [],
    this.hint,
    this.disabledHint,
    this.onChanged,
    this.onTap,
    this.buttonPadding = const EdgeInsetsDirectional.only(start: 16.0, end: 4.0),
    this.menuItemPadding = EdgeInsetsDirectional.zero,
    this.elevation = 8,
    this.style,
    this.decoration,
    this.disabledColor,
    this.enabledColor,
    this.isDense = false,
    this.isExpanded = false,
    this.height = kFieldHeight,
    this.itemHeight,
    this.itemConstraints = kMenuItemConstraints,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.dropdownMenuItemsFocusColor,
    this.dropdownMenuItemsHoverColor,
    this.menuMinHeight = kMenuItemMinHeight,
    this.menuMaxHeight,
    this.multiselect = true,
    this.enabled = true,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    // When adding new arguments, consider adding similar arguments to
    // DropdownFormField.
  })  : assert(itemHeight == null || itemHeight >= kMenuItemHeight),
        _isEmpty = false,
        _isFocused = false;

  const DropdownField._formField({
    super.key,
    required this.items,
    required this.childBuilder,
    required this.itemBuilder,
    this.refreshable = true,
    this.refreshDropdownMenuItemsOnChange = false,
    this.initialSelected = const [],
    this.hint,
    this.disabledHint,
    this.onChanged,
    this.onTap,
    this.buttonPadding = const EdgeInsetsDirectional.only(start: 16.0, end: 4.0),
    this.menuItemPadding = EdgeInsetsDirectional.zero,
    this.elevation = 8,
    this.style,
    this.disabledColor,
    this.enabledColor,
    this.isDense = false,
    this.isExpanded = false,
    this.height = kFieldHeight,
    this.itemHeight,
    this.itemConstraints = kMenuItemConstraints,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.dropdownMenuItemsFocusColor,
    this.dropdownMenuItemsHoverColor,
    this.menuMinHeight = kMenuItemMinHeight,
    this.menuMaxHeight,
    this.multiselect = true,
    this.enabled = true,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    required this.decoration,
    required bool isEmpty,
    required bool isFocused,
  })  : assert(itemHeight == null || itemHeight >= kMenuItemHeight),
        _isEmpty = isEmpty,
        _isFocused = isFocused;

  /// The list of items the user can select.
  ///
  /// If the [onChanged] callback is null or the list of items is null
  /// then the dropdown button will be disabled, i.e. its arrow will be
  /// displayed in grey and it will not respond to input.
  final List<T> items;

  /// The value of the currently selected [DropdownMenuItem].
  ///
  /// If [initialSelected] is null and the button is enabled, [hint] will be displayed
  /// if it is non-null.
  ///
  /// If [initialSelected] is null and the button is disabled, [disabledHint] will be displayed
  /// if it is non-null. If [disabledHint] is null, then [hint] will be displayed
  /// if it is non-null.
  final Iterable<int> initialSelected;

  final DropdownChildBuilder<T> childBuilder;

  final DropdownItemBuilder<T> itemBuilder;

  final bool refreshable;

  final bool refreshDropdownMenuItemsOnChange;

  /// A placeholder widget that is displayed by the dropdown button.
  ///
  /// If [initialSelected] is null and the dropdown is enabled ([dropdownMenuItems] and [onChanged] are non-null),
  /// this widget is displayed as a placeholder for the dropdown button's value.
  ///
  /// If [initialSelected] is null and the dropdown is disabled and [disabledHint] is null,
  /// this widget is used as the placeholder.
  final Widget? hint;

  /// A preferred placeholder widget that is displayed when the dropdown is disabled.
  ///
  /// If [initialSelected] is null, the dropdown is disabled ([dropdownMenuItems] or [onChanged] is null),
  /// this widget is displayed as a placeholder for the dropdown button's value.
  final Widget? disabledHint;

  /// {@template flutter.material.dropdownButton.onChanged}
  /// Called when the user selects an item.
  ///
  /// If the [onChanged] callback is null or the list of [DropdownField.dropdownMenuItems]
  /// is null then the dropdown button will be disabled, i.e. its arrow will be
  /// displayed in grey and it will not respond to input. A disabled button
  /// will display the [DropdownField.disabledHint] widget if it is non-null.
  /// If [DropdownField.disabledHint] is also null but [DropdownField.hint] is
  /// non-null, [DropdownField.hint] will instead be displayed.
  /// {@endtemplate}
  final ValueChanged<Iterable<int>>? onChanged;

  /// Called when the dropdown button is tapped.
  ///
  /// This is distinct from [onChanged], which is called when the user
  /// selects an item from the dropdown.
  ///
  /// The callback will not be invoked if the dropdown button is disabled.
  final OnTapCallback? onTap;

  final EdgeInsetsDirectional buttonPadding;

  final EdgeInsetsDirectional menuItemPadding;

  /// The z-coordinate at which to place the menu when open.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12,
  /// 16, and 24. See [kElevationToShadow].
  ///
  /// Defaults to 8, the appropriate elevation for dropdown buttons.
  final int elevation;

  /// The text style to use for text in the dropdown button and the dropdown
  /// menu that appears when you tap the button.
  ///
  /// To use a separate text style for selected item when it's displayed within
  /// the dropdown button, consider using [selectedItemBuilder].
  ///
  /// {@tool dartpad}
  /// This sample shows a `DropdownField` with a dropdown button text style
  /// that is different than its menu items.
  ///
  /// ** See code in examples/api/lib/material/dropdown/dropdown_button.style.0.dart **
  /// {@end-tool}
  ///
  /// Defaults to the [TextTheme.titleMedium] value of the current
  /// [ThemeData.textTheme] of the current [Theme].
  final TextStyle? style;

  /// The color of any [Icon] descendant of [trailing] if this button is disabled,
  /// i.e. if [onChanged] is null.
  ///
  /// Defaults to [MaterialColor.shade400] of [Colors.grey] when the theme's
  /// [ThemeData.brightness] is [Brightness.light] and to
  /// [Colors.white10] when it is [Brightness.dark]
  final Color? disabledColor;

  /// The color of any [Icon] descendant of [trailing] if this button is enabled,
  /// i.e. if [onChanged] is defined.
  ///
  /// Defaults to [MaterialColor.shade700] of [Colors.grey] when the theme's
  /// [ThemeData.brightness] is [Brightness.light] and to
  /// [Colors.white70] when it is [Brightness.dark]
  final Color? enabledColor;

  /// Reduce the button's height.
  ///
  /// By default this button's height is the same as its menu items' heights.
  /// If isDense is true, the button's height is reduced by about half. This
  /// can be useful when the button is embedded in a container that adds
  /// its own decorations, like [InputDecorator].
  final bool isDense;

  /// Set the dropdown's inner contents to horizontally fill its parent.
  ///
  /// By default this button's inner width is the minimum size of its contents.
  /// If [isExpanded] is true, the inner width is expanded to fill its
  /// surrounding container.
  final bool isExpanded;

  final double? height;

  /// If null, then the menu item heights will vary according to each menu item's
  /// intrinsic height.
  ///
  /// The default value is [kMenuItemHeight], which is also the minimum
  /// height for menu items.
  ///
  /// If this value is null and there isn't enough vertical room for the menu,
  /// then the menu's initial scroll offset may not align the selected item with
  /// the dropdown button. That's because, in this case, the initial scroll
  /// offset is computed as if all of the menu item heights were
  /// [kMenuItemHeight].
  final double? itemHeight;

  final BoxConstraints itemConstraints;

  /// The color for the button's [Material] when it has the input focus.
  final Color? focusColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The background color of the dropdown.
  ///
  /// If it is not provided, the theme's [ThemeData.canvasColor] will be used
  /// instead.
  final Color? dropdownColor;

  final Color? dropdownMenuItemsFocusColor;

  final Color? dropdownMenuItemsHoverColor;

  /// Padding around the visible portion of the dropdown widget.
  ///
  /// As the padding increases, the size of the [DropdownField] will also
  /// increase. The padding is included in the clickable area of the dropdown
  /// widget, so this can make the widget easier to click.
  ///
  /// Padding can be useful when used with a custom border. The clickable
  /// area will stay flush with the border, as opposed to an external [Padding]
  /// widget which will leave a non-clickable gap.
  final EdgeInsetsGeometry? padding;

  /// The maximum height of the menu.
  ///
  /// The maximum height of the menu must be at least one row shorter than
  /// the height of the app's view. This ensures that a tappable area
  /// outside of the simple menu is present so the user can dismiss the menu.
  ///
  /// If this property is set above the maximum allowable height threshold
  /// mentioned above, then the menu defaults to being padded at the top
  /// and bottom of the menu by at one menu item's height.
  final double? menuMaxHeight;

  final double? menuMinHeight;

  final bool multiselect;

  bool get singleSelect => !multiselect;

  final bool enabled;

  bool get disabled => !enabled;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// By default, platform-specific feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// Defines how the hint or the selected item is positioned within the button.
  ///
  /// Defaults to [AlignmentDirectional.centerStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// Defines the corner radii of the menu's rounded rectangle shape.
  final BorderRadius? borderRadius;

  final InputDecoration? decoration;

  final bool _isEmpty;

  final bool _isFocused;

  @override
  State<DropdownField<T>> createState() => DropdownFieldState<T>();
}

class DropdownFieldState<T> extends State<DropdownField<T>> with WidgetsBindingObserver {
  final selectedIndexes = <int>[];
  var dropdownMenuItems = <DropdownMenuItem<T>>[];
  DropdownRoute<T>? _dropdownRoute;
  Orientation? _lastOrientation;
  FocusNode? _internalNode;

  FocusNode? get focusNode => widget.focusNode ?? _internalNode;
  late Map<Type, Action<Intent>> _actionMap;

  // Only used if needed to create _internalNode.
  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  @override
  void initState() {
    super.initState();

    selectedIndexes.addAll(widget.initialSelected);

    if (!widget.refreshDropdownMenuItemsOnChange) _buildDropdownMenuItems();

    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _handleTap()),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _handleTap()),
    };
  }

  void _buildDropdownMenuItems() {
    dropdownMenuItems = [
      for (var index = 0; index < widget.items.length; index++)
        DropdownMenuItem(
          index: index,
          value: widget.items.elementAt(index),
          child: widget.itemBuilder(context, widget.items.elementAt(index), index, selectedIndexes.contains(index)),
        )
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    _internalNode?.dispose();
    super.dispose();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
    _lastOrientation = null;
  }

  @override
  void didUpdateWidget(DropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.refreshable) {
      bool deepEquals(Iterable a, Iterable b) {
        if (a.length != b.length) return false;
        if (a.runtimeType != b.runtimeType) return false;
        for (int i = 0; i < a.length; i++) {
          if (a.elementAt(i) != b.elementAt(i)) return false;
        }
        return true;
      }

      if (!deepEquals(widget.initialSelected, oldWidget.initialSelected)) {
        selectedIndexes.clear();
        selectedIndexes.addAll(widget.initialSelected);
      }
    }
    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
  }

  TextStyle get _defaultTextStyle {
    var defaultTextStyle = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    defaultTextStyle = defaultTextStyle.copyWith(
      color: widget.enabled ? widget.enabledColor : widget.disabledColor ?? Theme.of(context).disabledColor,
    );

    return defaultTextStyle;
  }

  TextStyle get _textStyle => widget.style ?? _defaultTextStyle;

  void _handleTap() {
    final List<MenuItem<T>> menuItems = <MenuItem<T>>[
      for (int index = 0; index < dropdownMenuItems.length; index += 1)
        MenuItem<T>(
          item: dropdownMenuItems[index],
          onLayout: (Size size) {
            // If [_dropdownRoute] is null and onLayout is called, this means
            // that performLayout was called on a _DropdownRoute that has not
            // left the widget tree but is already on its way out.
            //
            // Since onLayout is used primarily to collect the desired heights
            // of each menu item before laying them out, not having the _DropdownRoute
            // collect each item's height to lay out is fine since the route is
            // already on its way out.
            if (_dropdownRoute == null) {
              return;
            }

            _dropdownRoute!.itemHeights[index] = size.height;
          },
        ),
    ];

    final NavigatorState navigator = Navigator.of(context);
    assert(_dropdownRoute == null);

    final RenderBox itemBox = context.findRenderObject()! as RenderBox;
    final itemSize = itemBox.size;
    final Offset itemOffset = itemBox.localToGlobal(Offset.zero, ancestor: navigator.context.findRenderObject());

    var maxHeight = widget.itemConstraints.maxHeight;
    var itemHeight = math.min(maxHeight, widget.itemHeight ?? double.infinity);
    if (itemHeight.isInfinite) itemHeight = 0;
    itemHeight = math.max(itemHeight, widget.itemConstraints.minHeight);
    itemHeight = math.max(itemHeight, itemSize.height);

    final Rect buttonRect = Rect.fromLTWH(itemOffset.dx, itemOffset.dy + itemSize.height + 8, itemSize.width, itemHeight);

    _dropdownRoute = DropdownRoute<T>(
      items: menuItems,
      buttonRect: buttonRect,
      padding: widget.menuItemPadding.resolve(Directionality.maybeOf(context)),
      selectedIndexes: widget.initialSelected.isNotEmpty ? widget.initialSelected : [0],
      elevation: widget.elevation,
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      style: _textStyle,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      itemHeight: widget.itemHeight,
      itemConstraints: widget.itemConstraints,
      dropdownColor: widget.dropdownColor,
      menuItemsFocusColor: widget.dropdownMenuItemsFocusColor,
      menuItemsHoverColor: widget.dropdownMenuItemsHoverColor,
      menuMinHeight: widget.menuMinHeight,
      menuMaxHeight: widget.menuMaxHeight,
      enableFeedback: widget.enableFeedback ?? true,
      borderRadius: widget.borderRadius,
    );

    focusNode?.requestFocus();
    navigator.push(_dropdownRoute!).then<void>((DropdownRouteResult<T>? newValue) {
      _removeDropdownRoute();
      if (!mounted || newValue == null) {
        return;
      }
      if (widget.refreshable) {
        setState(() {
          if (selectedIndexes.contains(newValue.index)) {
            selectedIndexes.remove(newValue.index);
          } else {
            if (!widget.multiselect) selectedIndexes.clear();
            selectedIndexes.add(newValue.index);
          }

          widget.onChanged?.call(selectedIndexes);
        });
      } else {
        widget.onChanged?.call([newValue.index]);
      }
          widget.onTap?.call(newValue.index);

    });

  }

  // When isDense is true, reduce the height of this button from _kMenuItemHeight to
  // _kDenseButtonHeight, but don't make it smaller than the text that it contains.
  // Similarly, we don't reduce the height of the button so much that its icon
  // would be clipped.
  double get _denseButtonHeight {
    final double fontSize = _textStyle.fontSize ?? Theme.of(context).textTheme.titleMedium!.fontSize!;
    final double scaledFontSize = MediaQuery.textScalerOf(context).scale(fontSize);
    return math.max(scaledFontSize, kDenseButtonHeight);
  }

  Color get _iconColor {
    // These colors are not defined in the Material Design spec.
    final Brightness brightness = Theme.of(context).brightness;
    if (widget.enabled) {
      return widget.enabledColor ??
          switch (brightness) {
            Brightness.light => Colors.grey.shade700,
            Brightness.dark => Colors.white70,
          };
    } else {
      return widget.disabledColor ??
          switch (brightness) {
            Brightness.light => Colors.grey.shade400,
            Brightness.dark => Colors.white10,
          };
    }
  }

  Orientation _getOrientation(BuildContext context) {
    Orientation? result = MediaQuery.maybeOrientationOf(context);
    if (result == null) {
      // If there's no MediaQuery, then use the view aspect to determine
      // orientation.
      final Size size = View.of(context).physicalSize;
      result = size.width > size.height ? Orientation.landscape : Orientation.portrait;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final Orientation newOrientation = _getOrientation(context);
    _lastOrientation ??= newOrientation;
    if (newOrientation != _lastOrientation) {
      _removeDropdownRoute();
      _lastOrientation = newOrientation;
    }

    if (widget.refreshDropdownMenuItemsOnChange) _buildDropdownMenuItems();

    return _buildChild(context);
  }
  
  Widget _buildChild(BuildContext context) {
    Widget child;

    final decoration = effectiveDecoration;
    if (widget.hint != null || widget.disabled && widget.disabledHint != null || decoration.hintText != null) {
      child = widget.childBuilder(context, widget.items, selectedIndexes) ??_buildHintWidget(context, decoration);
    } else {
      child = widget.childBuilder(context, widget.items, selectedIndexes) ?? Container();
    }

    child = DropdownMenuItemContainer(alignment: widget.alignment, child: child);

    if (!widget.isDense) {
      if (widget.height != null) {
        child = SizedBox(height: widget.height, child: child);
      } else {
        child = Column(mainAxisSize: MainAxisSize.min, children: [child]);
      }
    }

    child = DefaultTextStyle(
      style: _textStyle,
      child: Container(
        padding: widget.buttonPadding.resolve(Directionality.of(context)),
        height: widget.isDense ? _denseButtonHeight : null,
        child: child,
      ),
    );

    child = InputDecorator(
      decoration: decoration,
      isEmpty: widget._isEmpty,
      isFocused: widget._isFocused,
      child: child,
    );

    if (widget.padding != null) {
      child = Padding(padding: widget.padding!, child: child);
    }

    final MouseCursor effectiveMouseCursor = WidgetStateProperty.resolveAs<MouseCursor>(
      WidgetStateMouseCursor.clickable,
      <WidgetState>{
        if (!widget.enabled) WidgetState.disabled,
      },
    );

    return Semantics(
      button: true,
      child: Actions(
        actions: _actionMap,
        child: InkWell(
          mouseCursor: effectiveMouseCursor,
          onTap: widget.enabled ? _handleTap : null,
          canRequestFocus: widget.enabled,
          borderRadius: widget.borderRadius,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          focusColor: widget.focusColor ?? Theme.of(context).focusColor,
          enableFeedback: false,
          child: child,
        ),
      ),
    );
  }
  
  Widget _buildHintWidget(BuildContext context, InputDecoration decoration) {
    Widget enableHint = widget.hint ?? Text(decoration.hintText!);

    var hintWidget = widget.enabled ? enableHint : widget.disabledHint ?? enableHint;

    if (decoration.hintTextDirection != null) {
      hintWidget = Directionality(
        textDirection: decoration.hintTextDirection!,
        child: hintWidget,
      );
    }

    hintWidget = DefaultTextStyle(
      style: decoration.hintStyle ?? _textStyle.copyWith(color: Theme.of(context).hintColor),
      maxLines: decoration.hintMaxLines,
      child: hintWidget,
    );

    if (decoration.hintFadeDuration != null) {
      var opacity = 1.0;
      // TODO: not completed
      // WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => opacity = 0));
      hintWidget = AnimatedOpacity(
        opacity: opacity,
        duration: decoration.hintFadeDuration!,
        child: hintWidget,
      );
    }

    return IgnorePointer(child: hintWidget);
  }

  InputDecoration get effectiveDecoration {
    var result = widget.decoration ?? const InputDecoration();
    if (result.suffix == null && result.suffixIcon == null && result.suffixText == null) {
      result = result
          .applyDefaults(Theme.of(context).inputDecorationTheme)
          .copyWith(
        suffixIcon: const Icon(Icons.arrow_drop_down),
        suffixIconColor: _iconColor,
      );
    }
    return result;
  }
}

/// A [FormField] that contains a [DropdownField].
///
/// This is a convenience widget that wraps a [DropdownField] widget in a
/// [FormField].
///
/// A [Form] ancestor is not required. The [Form] allows one to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
///
/// The `value` parameter maps to [FormField.initialValue].
///
/// See also:
///
///  * [DropdownField], which is the underlying text field without the [Form]
///    integration.
class DropdownFormField<T> extends FormField<Iterable<int>> {
  /// Creates a [DropdownField] widget that is a [FormField], wrapped in an
  /// [InputDecorator].
  ///
  /// For a description of the `onSaved`, `validator`, or `autovalidateMode`
  /// parameters, see [FormField]. For the rest (other than [decoration]), see
  /// [DropdownField].
  DropdownFormField({
    super.key,
    required List<T> items,
    required DropdownChildBuilder<T> childBuilder,
    required DropdownItemBuilder<T> itemBuilder,
    DropdownFieldBuilder? selectedItemBuilder,
    Iterable<int> initialSelected = const [],
    Widget? hint,
    Widget? disabledHint,
    required this.onChanged,
    OnTapCallback? onTap,
    int elevation = 8,
    TextStyle? style,
    Color? disabledColor,
    Color? enabledColor,
    bool isDense = true,
    bool isExpanded = false,
    double? itemHeight,
    Color? focusColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? dropdownColor,
    InputDecoration? decoration,
    super.onSaved,
    super.validator,
    AutovalidateMode? autovalidateMode,
    double? menuMaxHeight,
    bool? enableFeedback,
    AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    // When adding new arguments, consider adding similar arguments to
    // DropdownField.
  })  : assert(itemHeight == null || itemHeight >= kMenuItemHeight),
        decoration = decoration ?? InputDecoration(focusColor: focusColor),
        super(
          initialValue: initialSelected,
          autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
          builder: (field) {
            final state = field as DropdownFormFieldState<T>;
            final InputDecoration decorationArg = decoration ?? InputDecoration(focusColor: focusColor);
            final InputDecoration effectiveDecoration = decorationArg.applyDefaults(
              Theme.of(field.context).inputDecorationTheme,
            );

            final bool showSelectedItem = items.contains(state.value);
            bool isHintOrDisabledHintAvailable() {
              final bool isDropdownDisabled = onChanged == null || (items.isEmpty);
              if (isDropdownDisabled) {
                return hint != null || disabledHint != null;
              } else {
                return hint != null;
              }
            }

            final bool isEmpty = !showSelectedItem && !isHintOrDisabledHintAvailable();
            final bool hasError = effectiveDecoration.errorText != null;

            // An unfocusable Focus widget so that this widget can detect if its
            // descendants have focus or not.
            return Focus(
              canRequestFocus: false,
              skipTraversal: true,
              child: Builder(
                builder: (BuildContext context) {
                  final bool isFocused = Focus.of(context).hasFocus;
                  InputBorder? resolveInputBorder() {
                    if (hasError) {
                      if (isFocused) {
                        return effectiveDecoration.focusedErrorBorder;
                      }
                      return effectiveDecoration.errorBorder;
                    }
                    if (isFocused) {
                      return effectiveDecoration.focusedBorder;
                    }
                    if (effectiveDecoration.enabled) {
                      return effectiveDecoration.enabledBorder;
                    }
                    return effectiveDecoration.border;
                  }

                  BorderRadius? effectiveBorderRadius() {
                    final InputBorder? inputBorder = resolveInputBorder();
                    if (inputBorder is OutlineInputBorder) {
                      return inputBorder.borderRadius;
                    }
                    if (inputBorder is UnderlineInputBorder) {
                      return inputBorder.borderRadius;
                    }
                    return null;
                  }

                  return DropdownField<T>._formField(
                    items: items,
                    childBuilder: childBuilder,
                    itemBuilder: itemBuilder,
                    initialSelected: state.value ?? [],
                    hint: hint,
                    disabledHint: disabledHint,
                    onChanged: onChanged == null ? null : state.didChange,
                    onTap: onTap,
                    elevation: elevation,
                    style: style,
                    disabledColor: disabledColor,
                    enabledColor: enabledColor,
                    isDense: isDense,
                    isExpanded: isExpanded,
                    itemHeight: itemHeight,
                    focusColor: focusColor,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    dropdownColor: dropdownColor,
                    menuMaxHeight: menuMaxHeight,
                    enableFeedback: enableFeedback,
                    alignment: alignment,
                    borderRadius: borderRadius ?? effectiveBorderRadius(),
                    decoration: effectiveDecoration.copyWith(errorText: field.errorText),
                    isEmpty: isEmpty,
                    isFocused: isFocused,
                    padding: padding,
                  );
                },
              ),
            );
          },
        );

  /// {@macro flutter.material.dropdownButton.onChanged}
  final ValueChanged<Iterable<int>>? onChanged;

  /// The decoration to show around the dropdown button form field.
  ///
  /// By default, draws a horizontal line under the dropdown button field but
  /// can be configured to show an icon, label, hint text, and error text.
  ///
  /// If not specified, an [InputDecorator] with the `focusColor` set to the
  /// supplied `focusColor` (if any) will be used.
  final InputDecoration decoration;

  @override
  FormFieldState<Iterable<int>> createState() => DropdownFormFieldState<T>();
}

class DropdownFormFieldState<T> extends FormFieldState<Iterable<int>> {
  DropdownFormField<T> get _dropdownButtonFormField => widget as DropdownFormField<T>;

  @override
  void didChange(value) {
    super.didChange(value);
    _dropdownButtonFormField.onChanged!(value ?? []);
  }

  @override
  void didUpdateWidget(DropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }

  @override
  void reset() {
    super.reset();
    _dropdownButtonFormField.onChanged!(value ?? []);
  }
}
