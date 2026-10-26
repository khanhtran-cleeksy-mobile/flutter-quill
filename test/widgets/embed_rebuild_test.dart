import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Inline embed builder that counts how often it builds, and how often the
/// widget it returns is rebuilt.
class _CountingEmbedBuilder extends EmbedBuilder {
  int builds = 0;
  int widgetBuilds = 0;

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    builds++;
    return _Probe(onBuild: () => widgetBuilds++);
  }
}

class _Probe extends StatelessWidget {
  const _Probe({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const SizedBox(width: 20, height: 20);
  }
}

void main() {
  late QuillController controller;
  late _CountingEmbedBuilder embedBuilder;

  setUp(() {
    controller = QuillController(
      document: Document.fromJson([
        {'insert': 'a'},
        {
          'insert': {'image': 'https://x.com/a.png'},
        },
        {'insert': 'b\nhello\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    embedBuilder = _CountingEmbedBuilder();
  });

  tearDown(() => controller.dispose());

  Widget editor({bool readOnly = false, ThemeData? theme}) => MaterialApp(
        theme: theme,
        home: Scaffold(
          body: QuillEditor(
            controller: controller,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            scrollable: true,
            autoFocus: false,
            readOnly: readOnly,
            expands: false,
            padding: EdgeInsets.zero,
            embedBuilders: [embedBuilder],
          ),
        ),
      );

  testWidgets('typing and moving the caret elsewhere reuse the embed', (
    tester,
  ) async {
    await tester.pumpWidget(editor());
    expect(embedBuilder.builds, 1);
    expect(embedBuilder.widgetBuilds, 1);

    // Second line starts after "a", the embed, "b" and "\n".
    controller.replaceText(
      4,
      0,
      'x',
      const TextSelection.collapsed(offset: 5),
    );
    await tester.pump();
    controller.updateSelection(
      const TextSelection.collapsed(offset: 7),
      ChangeSource.LOCAL,
    );
    await tester.pump();

    expect(controller.document.toPlainText(), 'a￼b\nxhello\n');
    expect(embedBuilder.builds, 1);
    expect(embedBuilder.widgetBuilds, 1);
  });

  testWidgets('typing in the same line keeps the embed', (tester) async {
    await tester.pumpWidget(editor());
    controller.replaceText(
      3,
      0,
      'c',
      const TextSelection.collapsed(offset: 4),
    );
    await tester.pump();

    expect(controller.document.toPlainText(), 'a￼bc\nhello\n');
    expect(embedBuilder.builds, 1);
    expect(embedBuilder.widgetBuilds, 1);
  });

  testWidgets('formatting the embed rebuilds it', (tester) async {
    await tester.pumpWidget(editor());
    controller.formatText(1, 1, Attribute.bold);
    await tester.pump();

    expect(embedBuilder.builds, 2);
  });

  testWidgets('readOnly and theme changes rebuild it', (tester) async {
    await tester.pumpWidget(editor());
    await tester.pumpWidget(editor(readOnly: true));
    expect(embedBuilder.builds, 2);

    await tester.pumpWidget(
      editor(readOnly: true, theme: ThemeData(brightness: Brightness.dark)),
    );
    await tester.pumpAndSettle();
    // MaterialApp animates the theme change, so it rebuilds on each frame.
    expect(embedBuilder.builds, greaterThan(2));
  });

  testWidgets('a replaced embed is built again', (tester) async {
    await tester.pumpWidget(editor());
    controller.replaceText(
      1,
      1,
      BlockEmbed.image('https://x.com/b.png'),
      const TextSelection.collapsed(offset: 2),
    );
    await tester.pump();

    expect(embedBuilder.builds, 2);
  });
}
