// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/src/widgets/raw_editor.dart';

/// Displays the system context menu on top of the Flutter view.
///
/// Currently, only supports iOS 16.0 and above and displays nothing on other
/// platforms.
///
/// The context menu is the menu that appears, for example, when doing text
/// selection. Flutter typically draws this menu itself, but this class deals
/// with the platform-rendered context menu instead.
///
/// There can only be one system context menu visible at a time. Building this
/// widget when the system context menu is already visible will hide the old one
/// and display this one. A system context menu that is hidden is informed via
/// [onSystemHide].
///
/// To check if the current device supports showing the system context menu,
/// call [isSupported].
///
/// {@tool dartpad}
/// This example shows how to create a [TextField] that uses the system context
/// menu where supported and does not show a system notification when the user
/// presses the "Paste" button.
///
/// ** See code in examples/api/lib/widgets/system_context_menu/system_context_menu.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SystemContextMenuController], which directly controls the hiding and
///    showing of the system context menu.
class RawSystemContextMenu extends StatefulWidget {
  /// Creates an instance of [RawSystemContextMenu] that points to the given
  /// [anchor].
  const RawSystemContextMenu._({
    super.key,
    required this.anchor,
    this.onSystemHide,
  });

  /// Creates an instance of [RawSystemContextMenu] for the field indicated by the
  /// given [EditableTextState].
  factory RawSystemContextMenu.editableText({
    Key? key,
    required RawEditorState editableTextState,
  }) {
    final selection = editableTextState.contextMenuAnchors;
    return RawSystemContextMenu._(
      key: key,
      anchor: Rect.fromPoints(
        selection.primaryAnchor,
        selection.secondaryAnchor!,
      ),
      onSystemHide: () {
        //editableTextState.hideToolbar();
      },
    );
  }

  /// The [Rect] that the context menu should point to.
  final Rect anchor;

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

  @override
  State<RawSystemContextMenu> createState() => _RawSystemContextMenuState();
}

class _RawSystemContextMenuState extends State<RawSystemContextMenu> {
  late final SystemContextMenuController _systemContextMenuController;

  @override
  void initState() {
    super.initState();
    _systemContextMenuController = SystemContextMenuController(
      onSystemHide: widget.onSystemHide,
    );
    _systemContextMenuController.show(widget.anchor);
  }

  @override
  void didUpdateWidget(RawSystemContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.anchor != oldWidget.anchor) {
      _systemContextMenuController.show(widget.anchor);
    }
  }

  @override
  void dispose() {
    _systemContextMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(RawSystemContextMenu.isSupported(context));
    return const SizedBox.shrink();
  }
}
