import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'raw_editor.dart';

/// This class cloned from Flutter 3.32
class QuillSystemContextMenu extends StatefulWidget {
  /// Creates an instance of [SystemContextMenu] that points to the given
  /// [anchor].
  const QuillSystemContextMenu._({
    required this.anchor,
    required this.items,
    super.key,
    this.onSystemHide,
  });

  /// Creates an instance of [SystemContextMenu] for the field indicated by the
  /// given [EditableTextState].
  factory QuillSystemContextMenu.editableText({
    required RawEditorState rawEditorState,
    required List<IOSSystemContextMenuItem> items,
    Key? key,
  }) {
    return QuillSystemContextMenu._(
      key: key,
      anchor: rawEditorState.rect,
      items: items,
      onSystemHide: rawEditorState.hideToolbar,
    );
  }

  /// The [Rect] that the context menu should point to.
  final Rect anchor;

  /// A list of the items to be displayed in the system context menu.
  ///
  /// When passed, items will be shown regardless of the state of text input.
  /// For example, [IOSSystemContextMenuItemCopy] will produce a copy button
  /// even when there is no selection to copy. Use [EditableTextState] and/or
  /// the result of [getDefaultItems] to add and remove items based on the state
  /// of the input.
  ///
  /// Defaults to the result of [getDefaultItems].
  final List<IOSSystemContextMenuItem> items;

  /// Called when the system hides this context menu.
  ///
  /// For example, tapping outside of the context menu typically causes the
  /// system to hide the menu.
  ///
  /// This is not called when showing a new system context menu causes another
  /// to be hidden.
  final VoidCallback? onSystemHide;

  /// Whether the current device supports showing the system context menu.
  ///
  /// Currently, this is only supported on newer versions of iOS.
  static bool isSupported(BuildContext context) {
    return MediaQuery.maybeSupportsShowingSystemContextMenu(context) ?? false;
  }

  /// The default [items] for the given [EditableTextState].
  ///
  /// For example, [IOSSystemContextMenuItemCopy] will only be included when the
  /// field represented by the [EditableTextState] has a selection.
  ///
  /// See also:
  ///
  ///  * [EditableTextState.contextMenuButtonItems], which provides the default
  ///    [ContextMenuButtonItem]s for the Flutter-rendered context menu.
  static List<IOSSystemContextMenuItem> getDefaultItems(
      RawEditorState rawEditorState) {
    return <IOSSystemContextMenuItem>[
      if (rawEditorState.copyEnabled && rawEditorState.isSelectedText)
        const IOSSystemContextMenuItemCopy(),
      //

      if (rawEditorState.cutEnabled && rawEditorState.isSelectedText)
        const IOSSystemContextMenuItemCut(),
      if (rawEditorState.pasteEnabled) const IOSSystemContextMenuItemPaste(),
      if (rawEditorState.selectAllEnabled)
        const IOSSystemContextMenuItemSelectAll(),
      if (rawEditorState.lookUpEnabled) const IOSSystemContextMenuItemLookUp(),
      if (rawEditorState.searchWebEnabled)
        const IOSSystemContextMenuItemSearchWeb(),
    ];
  }

  @override
  State<QuillSystemContextMenu> createState() => _QuillSystemContextMenuState();
}

class _QuillSystemContextMenuState extends State<QuillSystemContextMenu> {
  late final SystemContextMenuController _systemContextMenuController;

  @override
  void initState() {
    super.initState();
    _systemContextMenuController =
        SystemContextMenuController(onSystemHide: widget.onSystemHide);
  }

  @override
  void dispose() {
    _systemContextMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(QuillSystemContextMenu.isSupported(context));

    if (widget.items.isNotEmpty) {
      final localizations = WidgetsLocalizations.of(context);
      final itemDatas =
          widget.items.map((item) => item.getData(localizations)).toList();
      _systemContextMenuController.showWithItems(widget.anchor, itemDatas);
    }

    return const SizedBox.shrink();
  }
}
