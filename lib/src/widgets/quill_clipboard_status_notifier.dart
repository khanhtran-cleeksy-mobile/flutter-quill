import 'package:flutter/widgets.dart';

/// [ClipboardStatusNotifier] that also treats the clipboard as pasteable when
/// [hasPasteableContent] reports non-text content (e.g. images), which
/// [ClipboardStatusNotifier] alone does not detect.
class QuillClipboardStatusNotifier extends ClipboardStatusNotifier {
  QuillClipboardStatusNotifier({required this.hasPasteableContent});

  final Future<bool> Function() hasPasteableContent;

  bool _isDisposed = false;

  @override
  Future<void> update() async {
    await super.update();
    if (_isDisposed || value == ClipboardStatus.pasteable) return;

    try {
      final hasContent = await hasPasteableContent();
      if (!_isDisposed && hasContent) value = ClipboardStatus.pasteable;
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
