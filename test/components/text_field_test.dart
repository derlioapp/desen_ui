import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsTextField and the text editing core (KALITE Faz 7a): gestures,
/// handles, edit menus, caret, selection, semantics and R3.
void main() {
  /// A full app: Overlay, Navigator and the text editing shortcuts.
  Widget app(
    Widget child, {
    DsThemeData? theme,
    MediaQueryData Function(MediaQueryData)? media,
  }) => DsApp(
    theme: theme ?? DsThemeData(),
    themeMode: DsThemeMode.light,
    builder: media == null
        ? null
        : (context, child) =>
              MediaQuery(data: media(MediaQuery.of(context)), child: child!),
    home: Center(child: SizedBox(width: 320, child: child)),
  );

  Finder field() => find.byType(DsTextField);

  EditableTextState editable(WidgetTester tester) =>
      tester.state<EditableTextState>(
        find.byWidgetPredicate((w) => w is EditableText),
      );

  DsBoxDecoration decoration(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: field(),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;

  /// The global position of the text offset [offset] in the field.
  Offset textOffset(WidgetTester tester, int offset) {
    final render = editable(tester).renderEditable;
    final caret = render.getLocalRectForCaret(TextPosition(offset: offset));
    return render.localToGlobal(caret.center);
  }

  /// Clipboard text set by the field, and what Paste reads.
  String? clipboard;
  void mockClipboard(WidgetTester tester) {
    clipboard = null;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboard = (call.arguments as Map)['text'] as String?;
          case 'Clipboard.getData':
            return clipboard == null ? null : {'text': clipboard};
          case 'Clipboard.hasStrings':
            return {'value': clipboard?.isNotEmpty ?? false};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  group('typing', () {
    testWidgets('types, reports changes and submits', (tester) async {
      final changes = <String>[];
      String? submitted;
      await tester.pumpWidget(
        app(
          DsTextField(
            onChanged: changes.add,
            onSubmitted: (v) => submitted = v,
          ),
        ),
      );
      await tester.enterText(field(), 'Merhaba');
      expect(changes.last, 'Merhaba');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, 'Merhaba');
    });

    testWidgets('initialValue seeds the field\'s own controller', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DsTextField(initialValue: 'abc')));
      expect(editable(tester).textEditingValue.text, 'abc');
    });

    testWidgets(
      'works without DsApp, DsScope or an Overlay (R3)',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          host(
            SizedBox(width: 300, child: DsTextField(controller: controller)),
          ),
        );
        await tester.tap(field());
        await tester.pump();
        await tester.enterText(field(), 'abc');
        // Backspace comes from DefaultTextEditingShortcuts, which the field
        // adds itself when no WidgetsApp does.
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        expect(controller.text, 'ab');
        // A right click needs an overlay for the menu; without one it
        // does nothing and does not throw.
        await tester.tapAt(
          tester.getCenter(field()),
          buttons: kSecondaryButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        expect(find.byType(DsMenu), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('maxLength stops input at the limit', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(DsTextField(controller: controller, maxLength: 5)),
      );
      await tester.enterText(field(), 'abcdefgh');
      expect(controller.text, 'abcde');
    });

    testWidgets('obscureText hides the text and offers no copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const DsTextField(obscureText: true, initialValue: 'secret')),
      );
      final state = editable(tester);
      expect(state.widget.obscureText, isTrue);
      state.userUpdateTextEditingValue(
        const TextEditingValue(
          text: 'secret',
          selection: TextSelection(baseOffset: 0, extentOffset: 6),
        ),
        SelectionChangedCause.keyboard,
      );
      expect(state.copyEnabled, isFalse);
      expect(state.cutEnabled, isFalse);
    });

    testWidgets('IME composing text gets the token underline', (tester) async {
      await tester.pumpWidget(app(const DsTextField()));
      await tester.tap(field());
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'nihon',
          selection: TextSelection.collapsed(offset: 5),
          composing: TextRange(start: 0, end: 5),
        ),
      );
      await tester.pump();
      final span = editable(tester).buildTextSpan();
      final composing = span.children![1] as TextSpan;
      expect(composing.text, 'nihon');
      expect(composing.style!.decoration, TextDecoration.underline);
      expect(composing.style!.decorationColor, DsThemeData().colors.indicator);
    });
  });

  group('desktop selection', () {
    final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

    Future<TestGesture> mouse(WidgetTester tester) async {
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      return g;
    }

    Future<void> click(WidgetTester tester, TestGesture g, Offset at) async {
      await g.down(at);
      await g.up();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('double-click selects a word, triple-click the paragraph', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const DsTextField(initialValue: 'hello brave world')),
      );
      final g = await mouse(tester);
      final at = textOffset(tester, 8); // inside "brave"
      await click(tester, g, at);
      await click(tester, g, at);
      expect(
        editable(tester).textEditingValue.selection,
        const TextSelection(baseOffset: 6, extentOffset: 11),
      );
      await click(tester, g, at);
      final s = editable(tester).textEditingValue.selection;
      expect((s.start, s.end), (0, 17));
      await tester.pump(const Duration(seconds: 1));
    }, variant: desktop);

    testWidgets('drag selects; shift-click extends', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField(initialValue: 'hello brave world')),
      );
      final g = await mouse(tester);
      await g.down(textOffset(tester, 0));
      await tester.pump();
      await g.moveTo(textOffset(tester, 5));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(seconds: 1));
      var s = editable(tester).textEditingValue.selection;
      expect((s.start, s.end), (0, 5));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await click(tester, g, textOffset(tester, 11));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      s = editable(tester).textEditingValue.selection;
      expect((s.start, s.end), (0, 11));
      await tester.pump(const Duration(seconds: 1));
    }, variant: desktop);
  });

  group('desktop edit menu', () {
    Future<void> rightClick(WidgetTester tester, Offset at) async {
      await tester.tapAt(
        at,
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
    }

    DsMenuItem item(WidgetTester tester, String label) => tester.widget(
      find.ancestor(of: find.text(label), matching: find.byType(DsMenuItem)),
    );

    testWidgets(
      'right click opens the menu at the pointer with shortcuts',
      (tester) async {
        mockClipboard(tester);
        await tester.pumpWidget(
          app(const DsTextField(initialValue: 'hello world')),
        );
        final at = textOffset(tester, 2);
        await rightClick(tester, at);
        expect(find.byType(DsMenu), findsOneWidget);
        for (final label in ['Cut', 'Copy', 'Paste']) {
          expect(find.text(label), findsOneWidget);
        }
        // macOS edit menus have no Select all.
        expect(
          find.text('Select all'),
          defaultTargetPlatform == TargetPlatform.macOS
              ? findsNothing
              : findsOneWidget,
        );
        final shortcut = defaultTargetPlatform == TargetPlatform.macOS
            ? '⌘C'
            : 'Ctrl+C';
        expect(item(tester, 'Copy').shortcut, shortcut);
        // Opens at the pointer: the menu's top left is just off it.
        final menu = tester.getTopLeft(find.byType(DsMenu));
        expect((menu - at).distance, lessThan(24));
        // macOS selects the word under the pointer; others keep the caret.
        final s = editable(tester).textEditingValue.selection;
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          expect((s.start, s.end), (0, 5));
          expect(item(tester, 'Copy').onPressed, isNotNull);
        }
        // Nothing on the clipboard: Paste is shown, disabled.
        expect(item(tester, 'Paste').onPressed, isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }),
    );

    testWidgets('cut, copy and paste go through the clipboard', (tester) async {
      mockClipboard(tester);
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(DsTextField(controller: controller)));
      // Right click on "world" selects it (macOS).
      await rightClick(tester, textOffset(tester, 8));
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(clipboard, 'world');
      expect(find.byType(DsMenu), findsNothing);
      // Focus came back and the selection stayed (no select-all).
      final s = editable(tester).textEditingValue.selection;
      expect((s.start, s.end), (6, 11));
      expect(
        tester
            .state<EditableTextState>(
              find.byWidgetPredicate((w) => w is EditableText),
            )
            .widget
            .focusNode
            .hasFocus,
        isTrue,
      );

      await rightClick(tester, textOffset(tester, 8));
      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();
      expect(controller.text, 'hello ');

      await rightClick(tester, textOffset(tester, 2));
      expect(item(tester, 'Paste').onPressed, isNotNull);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(controller.text, contains('world'));
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a read-only field offers Copy, not Cut or Paste', (
      tester,
    ) async {
      mockClipboard(tester);
      clipboard = 'x';
      await tester.pumpWidget(
        app(const DsTextField(initialValue: 'hello world', readOnly: true)),
      );
      // Select "hello" with a double click, then open the menu on it.
      await tester.tapAt(textOffset(tester, 2), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(textOffset(tester, 2), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 500));
      await rightClick(tester, textOffset(tester, 2));
      expect(item(tester, 'Cut').onPressed, isNull);
      expect(item(tester, 'Paste').onPressed, isNull);
      expect(item(tester, 'Copy').onPressed, isNotNull);
      expect(item(tester, 'Select all').onPressed, isNotNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('the keyboard opens and walks the menu', (tester) async {
      mockClipboard(tester);
      await tester.pumpWidget(app(const DsTextField(initialValue: 'abc')));
      await tester.tap(field());
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsNothing);
      expect(editable(tester).widget.focusNode.hasFocus, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('look and focus', () {
    bool hasOutline(DsBoxDecoration d) => d.shadows.any((x) => x.isOutline);

    DsShadow? edgeRing(DsBoxDecoration d) =>
        d.shadows.where((x) => x.inset && x.color.a > 0).firstOrNull;
    Color? edge(DsBoxDecoration d) => edgeRing(d)?.color;

    testWidgets('a click shows focus too: one 2px focus edge, no ring', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(app(const DsTextField(), theme: theme));
      expect(edge(decoration(tester)), theme.colors.borderField);
      expect(edgeRing(decoration(tester))!.spread, 1);
      await tester.tapAt(
        tester.getCenter(field()),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      // A pointer hid keyboard focus for buttons, but a text field shows
      // focus on click, like :focus-visible on an <input>.
      expect(DsFocusVisibility.keyboard.value, isFalse);
      final d = decoration(tester);
      expect(edge(d), theme.colors.focus);
      expect(edgeRing(d)!.spread, 2);
      // The edge is the whole focus look: nothing circles the field.
      expect(hasOutline(d), isFalse);
      expect(d.shadows.where((x) => !x.inset && x.color.a > 0), isEmpty);
    });

    testWidgets('Tab reaches the field; a disabled one is skipped', (
      tester,
    ) async {
      final a = FocusNode(), b = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(onPressed: () {}, child: const Text('Before')),
              DsTextField(focusNode: a, enabled: false),
              DsTextField(focusNode: b),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(a.hasFocus, isFalse);
      expect(b.hasFocus, isTrue);
    });

    testWidgets('disabled keeps its edge in the disabled colors (K-66)', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(const DsTextField(enabled: false, initialValue: 'x'), theme: theme),
      );
      final d = decoration(tester);
      expect(d.color, theme.colors.disabled);
      expect(edge(d), theme.colors.border);
      await tester.tap(field(), warnIfMissed: false);
      await tester.pump();
      expect(editable(tester).widget.focusNode.hasFocus, isFalse);
    });

    testWidgets('a DsField error gives the 2px error edge and an icon', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('E-mail'),
            errorText: 'Enter a valid address.',
            child: DsTextField(),
          ),
          theme: theme,
        ),
      );
      final ring = decoration(tester).shadows
          .firstWhere((x) => x.inset && x.color.a > 0);
      expect(ring.spread, 2);
      expect(ring.color, theme.shadows.fieldError.first.color);
      expect(
        find.descendant(of: field(), matching: find.byType(DsIcon)),
        findsOneWidget,
      );
    });
  });

  group('touch selection', () {
    Finder painted(String painter) => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter.runtimeType.toString() == painter,
    );

    testWidgets(
      'Android: long press selects a word, shows teardrops and the toolbar',
      (tester) async {
        mockClipboard(tester);
        await tester.pumpWidget(
          app(const DsTextField(initialValue: 'hello brave world')),
        );
        await tester.longPressAt(textOffset(tester, 8));
        await tester.pumpAndSettle();
        final s = editable(tester).textEditingValue.selection;
        expect((s.start, s.end), (6, 11));
        expect(painted('_TeardropPainter'), findsNWidgets(2));
        expect(find.byType(DsTextSelectionToolbar), findsOneWidget);
        expect(find.text('Cut'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
        // Each handle takes at least a 44 point touch target (K-40).
        for (final handle in painted('_TeardropPainter').evaluate()) {
          final area = tester.getSize(
            find
                .ancestor(
                  of: find.byWidget(handle.widget),
                  matching: find.byType(RawGestureDetector),
                )
                .first,
          );
          expect(area.width, greaterThanOrEqualTo(44));
          expect(area.height, greaterThanOrEqualTo(44));
        }
        // The toolbar's buttons are the tap height.
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('Copy'),
                      matching: find.byType(DsPressable),
                    )
                    .first,
              )
              .height,
          greaterThanOrEqualTo(44),
        );
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(clipboard, 'brave');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('a tap places the caret with one caret handle', (tester) async {
      await tester.pumpWidget(app(const DsTextField(initialValue: 'hello')));
      await tester.tapAt(textOffset(tester, 2));
      await tester.pumpAndSettle();
      final s = editable(tester).textEditingValue.selection;
      expect(s.isCollapsed, isTrue);
      // Android hangs one teardrop under the caret; no toolbar yet.
      expect(painted('_TeardropPainter'), findsOneWidget);
      expect(find.byType(DsTextSelectionToolbar), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('iOS: lollipop handles; Desen toolbar as the fallback', (
      tester,
    ) async {
      mockClipboard(tester);
      await tester.pumpWidget(
        app(const DsTextField(initialValue: 'hello brave world')),
      );
      await tester.longPressAt(textOffset(tester, 8));
      await tester.pumpAndSettle();
      expect(painted('_LollipopPainter'), findsNWidgets(2));
      expect(find.byType(SystemContextMenu), findsNothing);
      expect(find.byType(DsTextSelectionToolbar), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('iOS: the native edit menu where the system has one', (
      tester,
    ) async {
      mockClipboard(tester);
      await tester.pumpWidget(
        app(
          const DsTextField(initialValue: 'hello brave world'),
          media: (m) => m.copyWith(supportsShowingSystemContextMenu: true),
        ),
      );
      await tester.longPressAt(textOffset(tester, 8));
      await tester.pumpAndSettle();
      expect(find.byType(SystemContextMenu), findsOneWidget);
      expect(find.byType(DsTextSelectionToolbar), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('every toolbar button has a localized, non-empty label', (
      tester,
    ) async {
      Future<List<String>> labels(Locale locale) async {
        await tester.pumpWidget(
          DsApp(
            theme: DsThemeData(),
            locale: locale,
            home: DsTextSelectionToolbar(
              anchors: const TextSelectionToolbarAnchors(
                primaryAnchor: Offset(200, 200),
              ),
              buttonItems: [
                for (final type in [
                  ContextMenuButtonType.delete,
                  ContextMenuButtonType.liveTextInput,
                  ContextMenuButtonType.custom,
                ])
                  ContextMenuButtonItem(type: type, onPressed: () {}),
                // An app's own action keeps its label; a blank one is
                // treated as missing.
                ContextMenuButtonItem(label: 'Translate', onPressed: () {}),
                ContextMenuButtonItem(label: ' ', onPressed: () {}),
                // A platform label never replaces Desen's own wording.
                ContextMenuButtonItem(
                  type: ContextMenuButtonType.delete,
                  label: 'DELETE',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        return [
          for (final e
              in find
                  .descendant(
                    of: find.byType(DsTextSelectionToolbar),
                    matching: find.byType(Text),
                  )
                  .evaluate())
            (e.widget as Text).data!,
        ];
      }

      expect(await labels(const Locale('en')), [
        'Delete',
        'Scan text',
        'Action',
        'Translate',
        'Action',
        'Delete',
      ]);
      expect(await labels(const Locale('tr')), [
        'Sil',
        'Metni tara',
        'İşlem',
        'Translate',
        'İşlem',
        'Sil',
      ]);
      // Every language and variant names them.
      for (final l10n in dsBundledLocalizations.values) {
        for (final label in [l10n.delete, l10n.scanText, l10n.editAction]) {
          expect(label.trim(), isNotEmpty, reason: l10n.localeName);
        }
      }
    });
  });

  group('semantics', () {
    testWidgets('a text field node with label, hint, length and state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsTextField(
            semanticLabel: 'Name',
            placeholder: 'Ada Lovelace',
            maxLength: 20,
            error: true,
          ),
        ),
      );
      var data = tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData();
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.label, 'Name');
      // The placeholder, then the counter as words.
      expect(data.hint, 'Ada Lovelace\n0 of 20 characters');
      expect(data.maxValueLength, 20);
      expect(data.currentValueLength, 0);
      expect(data.validationResult, SemanticsValidationResult.invalid);
      await tester.enterText(field(), 'Ada');
      await tester.pump();
      data = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
      expect(data.value, 'Ada');
      expect(data.currentValueLength, 3);
      expect(data.hint, '3 of 20 characters');
      handle.dispose();
    });

    testWidgets('inside a DsField: named by its label, required, one node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('E-mail'),
            required: true,
            errorText: 'Enter a valid address.',
            child: DsTextField(),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(EditableText));
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.label, startsWith('E-mail'));
      expect(data.hint, endsWith('Error\nEnter a valid address.'));
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(tester.getSemantics(find.text('E-mail')), same(node));
      handle.dispose();
    });

    testWidgets('disabled, read-only and obscured are reported', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsTextField(semanticLabel: 'a', enabled: false),
              DsTextField(semanticLabel: 'b', readOnly: true),
              DsTextField(semanticLabel: 'c', obscureText: true),
            ],
          ),
        ),
      );
      SemanticsData at(int i) => tester
          .getSemantics(find.byType(EditableText).at(i))
          .getSemanticsData();
      expect(at(0).flagsCollection.isEnabled, Tristate.isFalse);
      expect(at(1).flagsCollection.isReadOnly, isTrue);
      expect(at(2).flagsCollection.isObscured, isTrue);
      handle.dispose();
    });
  });

  group('edge cases', () {
    testWidgets('RTL: text and the error icon mirror', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: DsTextField(initialValue: 'שלום', error: true),
          ),
          direction: TextDirection.rtl,
        ),
      );
      final icon = tester.getCenter(find.byType(DsIcon));
      expect(icon.dx, lessThan(tester.getCenter(field()).dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('text scale 2.0 grows the field without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: DsTextField(placeholder: 'Search the archive'),
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(field()).height, greaterThan(40));
    });

    testWidgets('in an unbounded width it takes its default width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Row(mainAxisSize: MainAxisSize.min, children: [DsTextField()]),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(field()).width, 240);
    });

    testWidgets('multi-line grows to maxLines', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField.multiline(maxLines: 4, minLines: 2)),
      );
      final two = tester.getSize(field()).height;
      await tester.enterText(field(), 'a\nb\nc\nd\ne\nf');
      await tester.pump();
      final four = tester.getSize(field()).height;
      expect(four, greaterThan(two));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the caret blinks as the platform does', (tester) async {
      await tester.pumpWidget(app(const DsTextField()));
      await tester.tap(field());
      await tester.pump();
      final state = editable(tester);
      final caret = DsThemeData().colors.indicator;
      expect(state.renderEditable, paints..rrect(color: caret));
      await tester.pump(state.cursorBlinkInterval);
      expect(state.renderEditable, isNot(paints..rrect(color: caret)));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('reduced motion: the caret stays still', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(app(const DsTextField()));
      await tester.tap(field());
      await tester.pump();
      await tester.pump();
      final state = editable(tester);
      expect(state.widget.showCursor, isFalse);
      expect(state.renderEditable.foregroundPainter, isNotNull);
      // Still there a blink interval later, and the one after.
      final caret = DsThemeData().colors.indicator;
      for (var i = 0; i < 2; i++) {
        await tester.pump(state.cursorBlinkInterval);
        expect(state.renderEditable, paints..rrect(color: caret));
      }
    });

    testWidgets('fields in an AutofillGroup register with it', (tester) async {
      await tester.pumpWidget(
        app(
          const AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsTextField(autofillHints: [AutofillHints.username]),
                DsTextField(
                  autofillHints: [AutofillHints.password],
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
      );
      final group = tester.state<AutofillGroupState>(
        find.byType(AutofillGroup),
      );
      expect(group.autofillClients, hasLength(2));
    });

    testWidgets('a hovered field strengthens its edge', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(app(const DsTextField(), theme: theme));
      await hover(tester, field());
      expect(decoration(tester).shadows.first.color, theme.colors.textSubtle);
    });
  });
}
