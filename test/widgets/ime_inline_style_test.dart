import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

/// Vietnamese IMEs (Telex/VNI) often build accented characters by deleting
/// the last character and inserting the new one in two separate updates.
void main() {
  late QuillController controller;

  Future<void> pumpEditor(WidgetTester tester, String initial) async {
    controller = QuillController(
      document: Document()..insert(0, initial),
      selection: TextSelection.collapsed(offset: initial.length),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuillEditor(
            controller: controller,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            scrollable: true,
            autoFocus: true,
            readOnly: false,
            expands: false,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(QuillEditor));
    await tester.pump();
    controller.updateSelection(
      TextSelection.collapsed(offset: initial.length),
      ChangeSource.LOCAL,
    );
    await tester.pump();
  }

  /// Sends what the keyboard thinks the text is, with the caret at
  /// [caret] (end of [text] by default).
  Future<void> ime(
    WidgetTester tester,
    String text, {
    int? caret,
    TextRange composing = TextRange.empty,
    TextAffinity affinity = TextAffinity.downstream,
  }) async {
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: '$text\n',
      selection: TextSelection.collapsed(
        offset: caret ?? text.length,
        affinity: affinity,
      ),
      composing: composing,
    ));
    await tester.pump();
  }

  List<dynamic> ops() => controller.document.toDelta().toJson();

  // Recorded from the iOS Vietnamese (Telex) keyboard typing "d" "d" after
  // "abc ": it selects " d", deletes it, then types " " and "đ" again.
  testWidgets('iOS Telex re-typing " d" as " đ" keeps bold on đ', (
    tester,
  ) async {
    await pumpEditor(tester, 'abc ');
    controller.formatSelection(Attribute.bold);
    await ime(tester, 'abc d');
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'abc d\n',
      selection: TextSelection(baseOffset: 3, extentOffset: 5),
    ));
    await tester.pump();
    await ime(tester, 'abc');
    await ime(tester, 'abc ');
    await ime(tester, 'abc đ');

    expect(ops(), [
      {'insert': 'abc '},
      {
        'insert': 'đ',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ]);
    // Typing on continues in bold.
    await ime(tester, 'abc đi');
    expect(ops()[1], {
      'insert': 'đi',
      'attributes': {'bold': true},
    });
  });

  // Recorded on iOS: after bold "việt", bold is turned off and " d" typed;
  // the keyboard then deletes the plain " d" and re-types " đ" right after
  // the bold word.
  testWidgets('iOS Telex re-typing plain text after bold stays plain', (
    tester,
  ) async {
    await pumpEditor(tester, 'abc');
    controller
      ..formatText(0, 3, Attribute.bold)
      ..formatSelection(Attribute.clone(Attribute.bold, null));
    await ime(tester, 'abc ');
    await ime(tester, 'abc d');
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'abc d\n',
      selection: TextSelection(baseOffset: 3, extentOffset: 5),
    ));
    await tester.pump();
    await ime(tester, 'abc');
    await ime(tester, 'abc ');
    await ime(tester, 'abc đ');

    expect(ops(), [
      {
        'insert': 'abc',
        'attributes': {'bold': true},
      },
      {'insert': ' đ\n'},
    ]);
  });

  testWidgets('re-typing mixed styles restores each character', (
    tester,
  ) async {
    await pumpEditor(tester, 'ab');
    controller
      ..formatText(0, 1, Attribute.italic)
      ..formatText(1, 1, Attribute.bold);
    await ime(tester, '');
    await ime(tester, 'x');
    await ime(tester, 'xy');

    expect(ops(), [
      {
        'insert': 'x',
        'attributes': {'italic': true},
      },
      {
        'insert': 'y',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ]);
  });

  // Keyboards report the caret after typed text with upstream affinity.
  testWidgets('delete then insert after existing words keeps bold', (
    tester,
  ) async {
    await pumpEditor(tester, 'abc ');
    controller.formatSelection(Attribute.bold);
    for (final text in ['abc d', 'abc ', 'abc đ']) {
      await ime(tester, text, affinity: TextAffinity.upstream);
    }

    expect(ops(), [
      {'insert': 'abc '},
      {
        'insert': 'đ',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ]);
  });

  testWidgets('toggled bold survives a re-sent caret with another affinity', (
    tester,
  ) async {
    await pumpEditor(tester, 'abc ');
    controller
      ..formatSelection(Attribute.bold)
      ..updateSelection(
        const TextSelection.collapsed(
          offset: 4,
          affinity: TextAffinity.upstream,
        ),
        ChangeSource.LOCAL,
      );
    await ime(tester, 'abc d', affinity: TextAffinity.upstream);

    expect(ops()[1], {
      'insert': 'd',
      'attributes': {'bold': true},
    });
  });

  for (final attribute in [
    Attribute.bold,
    Attribute.italic,
    Attribute.underline,
  ]) {
    testWidgets('delete then insert keeps ${attribute.key}', (tester) async {
      await pumpEditor(tester, 'x');
      controller.formatSelection(attribute);
      await ime(tester, 'xd');
      await ime(tester, 'x');
      await ime(tester, 'xđ');

      expect(ops(), [
        {'insert': 'x'},
        {
          'insert': 'đ',
          'attributes': {attribute.key: true},
        },
        {'insert': '\n'},
      ]);
    });
  }

  testWidgets('a repeated caret update between delete and insert is kept', (
    tester,
  ) async {
    await pumpEditor(tester, 'x');
    controller.formatSelection(Attribute.bold);
    await ime(tester, 'xd');
    await ime(tester, 'x');
    controller.updateSelection(
      const TextSelection.collapsed(offset: 1),
      ChangeSource.LOCAL,
    );
    await ime(tester, 'xđ');

    expect(ops()[1], {
      'insert': 'đ',
      'attributes': {'bold': true},
    });
  });

  testWidgets('single replace and composing words keep bold', (tester) async {
    await pumpEditor(tester, 'x ');
    controller.formatSelection(Attribute.bold);
    for (final text in ['x v', 'x vi', 'x vie', 'x viet', 'x việt']) {
      await ime(tester, text, composing: TextRange(start: 2, end: text.length));
    }
    await ime(tester, 'x việt');

    expect(ops(), [
      {'insert': 'x '},
      {
        'insert': 'việt',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ]);
  });

  testWidgets('moving the caret after a delete drops the kept style', (
    tester,
  ) async {
    await pumpEditor(tester, 'ab');
    controller.formatText(1, 1, Attribute.bold);
    // Delete the bold "b", move to the start and type there.
    await ime(tester, 'a');
    controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.LOCAL,
    );
    await ime(tester, 'a', caret: 0);
    await ime(tester, 'ca', caret: 1);

    expect(ops(), [
      {'insert': 'ca\n'},
    ]);
  });

  testWidgets('links are not carried over', (tester) async {
    await pumpEditor(tester, 'ab');
    controller
      ..formatText(1, 1, const LinkAttribute('https://a.com'))
      ..formatText(1, 1, Attribute.bold);
    await ime(tester, 'a');
    await ime(tester, 'ac');

    expect(ops(), [
      {'insert': 'a'},
      {
        'insert': 'c',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ]);
  });
}
