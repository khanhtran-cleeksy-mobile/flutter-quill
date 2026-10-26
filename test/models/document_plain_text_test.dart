import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Document.toPlainText cache', () {
    test('returns the same string while the document is unchanged', () {
      final document = Document()..insert(0, 'abc');
      expect(identical(document.toPlainText(), document.toPlainText()), isTrue);
    });

    test('reflects every kind of change', () {
      final document = Document();
      expect(document.toPlainText(), '\n');

      document.insert(0, 'hello');
      expect(document.toPlainText(), 'hello\n');

      document.replace(0, 5, 'bye');
      expect(document.toPlainText(), 'bye\n');

      document.delete(0, 1);
      expect(document.toPlainText(), 'ye\n');

      document.insert(2, BlockEmbed.image('https://x.com/a.png'));
      expect(
        document.toPlainText(),
        'ye${Embed.kObjectReplacementCharacter}\n',
      );

      document.format(0, 2, Attribute.bold);
      expect(
        document.toPlainText(),
        'ye${Embed.kObjectReplacementCharacter}\n',
      );

      document.compose(
        Delta()..insert('x'),
        ChangeSource.REMOTE,
      );
      expect(
        document.toPlainText(),
        'xye${Embed.kObjectReplacementCharacter}\n',
      );
    });

    test('reflects undo and redo', () {
      final document = Document()..insert(0, 'a');
      document.insert(1, 'b');
      document.undo();
      expect(document.toPlainText(), document.root.toPlainText());
      document.redo();
      expect(document.toPlainText(), document.root.toPlainText());
    });

    test('matches the tree after documents are loaded', () {
      final document = Document.fromJson([
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'b\n'},
      ]);
      expect(document.toPlainText(), 'a\nb\n');
    });
  });

  group('QuillController', () {
    test('plainTextEditingValue follows text changes', () {
      final controller = QuillController.basic()
        ..replaceText(0, 0, 'abc', const TextSelection.collapsed(offset: 3));
      expect(controller.plainTextEditingValue.text, 'abc\n');
      controller.replaceText(1, 1, '', const TextSelection.collapsed(offset: 1));
      expect(controller.plainTextEditingValue.text, 'ac\n');
      expect(
        controller.plainTextEditingValue.selection,
        const TextSelection.collapsed(offset: 1),
      );
    });
  });
}
