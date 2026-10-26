import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

double _baseline(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  final top = box.localToGlobal(Offset.zero).dy;
  // Baselines may only be read during layout; allow it for the assertion.
  RenderObject.debugCheckingIntrinsics = true;
  final baseline = box.getDistanceToBaseline(TextBaseline.alphabetic)!;
  RenderObject.debugCheckingIntrinsics = false;
  return top + baseline;
}

Finder _line(String text) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().startsWith(text));

void main() {
  const body = TextStyle(fontSize: 14, height: 1.6, color: Colors.black);
  const spacing = VerticalSpacing(0, 0);

  // A leading style that differs from the body, so only baseline alignment
  // can line them up.
  const bigLeading = TextStyle(fontSize: 20, height: 1.2);

  Future<void> pumpEditor(
    WidgetTester tester,
    List<dynamic> ops, {
    TextStyle? leading,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuillEditor(
            controller: QuillController(
              document: Document.fromJson(ops),
              selection: const TextSelection.collapsed(offset: 0),
            ),
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            scrollable: true,
            autoFocus: false,
            readOnly: false,
            expands: false,
            padding: EdgeInsets.zero,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(body, spacing, spacing, null),
              lists: DefaultListBlockStyle(body, spacing, spacing, null, null),
              leading: leading == null
                  ? null
                  : DefaultTextBlockStyle(leading, spacing, spacing, null),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('bullets and numbers sit on the first line baseline', (
    tester,
  ) async {
    await pumpEditor(tester, [
      {'insert': 'Bullet'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {'insert': 'Nested'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet', 'indent': 1},
      },
      {'insert': 'Number'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
    ], leading: bigLeading);

    final bullets = find.text('•');
    expect(
      _baseline(tester, bullets.at(0)),
      moreOrLessEquals(_baseline(tester, _line('Bullet')), epsilon: 0.5),
    );
    expect(
      _baseline(tester, bullets.at(1)),
      moreOrLessEquals(_baseline(tester, _line('Nested')), epsilon: 0.5),
    );
    expect(
      _baseline(tester, find.text('1.')),
      moreOrLessEquals(_baseline(tester, _line('Number')), epsilon: 0.5),
    );
  });

  testWidgets('checkboxes stay at the top of the line', (tester) async {
    await pumpEditor(tester, [
      {'insert': 'Task'},
      {
        'insert': '\n',
        'attributes': {'list': 'unchecked'},
      },
    ]);

    final checkbox = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'CheckboxPoint');
    expect(
      tester.getTopLeft(checkbox).dy,
      tester.getTopLeft(_line('Task')).dy,
    );
  });

  testWidgets('without a custom leading, bullets use the paragraph style', (
    tester,
  ) async {
    await pumpEditor(tester, [
      {'insert': 'Bullet'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {'insert': 'Number'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
    ]);

    for (final leading in [find.text('•'), find.text('1.')]) {
      final style = tester.widget<Text>(leading).style!;
      expect(style.fontSize, body.fontSize);
      expect(style.height, body.height);
      expect(style.color, body.color);
    }
  });

  testWidgets('a custom leading style still wins', (tester) async {
    await pumpEditor(tester, [
      {'insert': 'Bullet'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
    ], leading: bigLeading);

    expect(tester.widget<Text>(find.text('•')).style!.fontSize, 20);
  });
}
