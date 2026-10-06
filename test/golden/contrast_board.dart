import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// A compact, app-like board for comparing contrast levels side by side:
/// a card of list rows with separators, a field with label and helper
/// text, the selection controls, a segmented control, chips with one
/// selected, a button row, badges, a progress bar and a menu with a
/// highlighted row.
///
/// The menu highlight follows focus, and only one widget holds focus at a
/// time, so each column is drawn on its own with its row hovered, then laid
/// beside the others as an image.
Future<void> pumpContrastBoard(
  WidgetTester tester, {
  required Brightness brightness,
  required List<DsContrast> contrasts,
}) async {
  final images = <ui.Image>[];
  addTearDown(() {
    for (final i in images) {
      i.dispose();
    }
  });
  final shots = <Widget>[];
  // A desktop pointer: hover shows (touch mode hides it).
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  for (final (i, c) in contrasts.indexed) {
    final theme = DsThemeData(
      brightness: brightness,
      contrast: c,
      platform: goldenPlatform,
      motion: const DsMotion(reduced: true),
    );
    await pumpGolden(
      tester,
      theme: theme,
      size: const Size(600, 1200),
      KeyedSubtree(
        key: UniqueKey(),
        child: DsScope(
          theme: theme,
          darkTheme: theme,
          themeMode: theme.isDark ? DsThemeMode.dark : DsThemeMode.light,
          followPlatformContrast: false,
          animateChanges: false,
          child: _Column(title: c.name, theme: theme),
        ),
      ),
    );
    // A mouse of its own each time, so no hover carries over.
    final mouse = TestGesture(
      dispatcher: tester.sendEventToBinding,
      kind: PointerDeviceKind.mouse,
      pointer: 100 + i,
      device: 100 + i,
    );
    // A click on the empty margin first: a pointer user sees no focus
    // ring on the row the hover focuses.
    await mouse.addPointer(location: const Offset(2, 2));
    await mouse.down(const Offset(2, 2));
    await mouse.up();
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(_menuRow)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final boundary =
        goldenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: tester.view.devicePixelRatio),
    ))!;
    images.add(image);
    await mouse.removePointer();
    shots.add(RawImage(image: image, scale: tester.view.devicePixelRatio));
  }
  await pumpGolden(
    tester,
    theme: DsThemeData(brightness: brightness, platform: goldenPlatform),
    size: const Size(1400, 1200),
    Row(mainAxisSize: MainAxisSize.min, children: shots),
  );
}

const _menuRow = ValueKey('contrast-board-menu-row');

class _Column extends StatelessWidget {
  const _Column({required this.title, required this.theme});

  final String title;
  final DsThemeData theme;

  @override
  Widget build(BuildContext context) {
    final k = theme.colors;
    final caption = theme.typography.caption.copyWith(color: k.textSubtle);
    return ColoredBox(
      color: k.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Text(
                title,
                style: theme.typography
                    .mono(theme.typography.caption)
                    .copyWith(color: k.textMuted),
              ),
              DsListSection(
                header: const Text('HESAP'),
                children: [
                  DsListRow(
                    leading: const DsIcon(DsIcons.bell),
                    title: const Text('Bildirimler'),
                    detail: const Text('Açık'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.user),
                    title: const Text('Profil'),
                    detail: const Text('Emre'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.logOut),
                    title: const Text('Oturumu kapat'),
                    destructive: true,
                    onPressed: () {},
                  ),
                ],
              ),
              const DsField(
                label: Text('E-posta'),
                description: Text('Kimseyle paylaşılmaz.'),
                child: DsTextField(placeholder: 'ad@ornek.com'),
              ),
              Row(
                spacing: 14,
                children: [
                  DsCheckbox(value: true, onChanged: (_) {}),
                  DsCheckbox(value: false, onChanged: (_) {}),
                  DsRadioGroup<int>(
                    value: 1,
                    onChanged: (_) {},
                    child: const Row(
                      spacing: 10,
                      children: [DsRadio(value: 1), DsRadio(value: 2)],
                    ),
                  ),
                  DsSwitch(value: true, onChanged: (_) {}),
                  DsSwitch(value: false, onChanged: (_) {}),
                ],
              ),
              DsSlider(value: .4, onChanged: (_) {}),
              DsSegmentedControl<int>(
                value: 1,
                onChanged: (_) {},
                segments: const [
                  DsSegment(value: 0, label: Text('Gün')),
                  DsSegment(value: 1, label: Text('Hafta')),
                  DsSegment(value: 2, label: Text('Ay')),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  DsChip(
                    label: const Text('Tümü'),
                    selected: true,
                    onChanged: (_) {},
                  ),
                  DsChip(
                    label: const Text('Açık'),
                    selected: false,
                    onChanged: (_) {},
                  ),
                  DsChip(
                    label: const Text('Kapalı'),
                    selected: false,
                    onChanged: (_) {},
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DsButton(
                    variant: DsButtonVariant.primary,
                    onPressed: () {},
                    child: const Text('Kaydet'),
                  ),
                  DsButton(
                    variant: DsButtonVariant.secondary,
                    onPressed: () {},
                    child: const Text('Vazgeç'),
                  ),
                  DsButton(
                    variant: DsButtonVariant.tinted,
                    onPressed: () {},
                    child: const Text('Paylaş'),
                  ),
                  DsButton(
                    variant: DsButtonVariant.dangerSoft,
                    onPressed: () {},
                    child: const Text('Sil'),
                  ),
                ],
              ),
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  DsBadge(label: Text('Taslak')),
                  DsBadge(status: DsStatus.info, label: Text('Yeni')),
                  DsBadge(status: DsStatus.success, label: Text('Canlı')),
                  DsBadge(status: DsStatus.warning, label: Text('Bekliyor')),
                  DsBadge(status: DsStatus.danger, label: Text('Hata')),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  Text('Yükleniyor · %60', style: caption),
                  const DsProgressBar(value: .6),
                ],
              ),
              DsMenu(
                children: [
                  DsMenuItem(
                    leading: const DsIcon(DsIcons.copy),
                    label: const Text('Kopyala'),
                    shortcut: '⌘C',
                    onPressed: () {},
                  ),
                  DsMenuItem(
                    key: _menuRow,
                    leading: const DsIcon(DsIcons.link),
                    label: const Text('Bağlantıyı kopyala'),
                    shortcut: '⇧⌘C',
                    onPressed: () {},
                  ),
                  DsMenuItem(
                    leading: const DsIcon(DsIcons.trash),
                    label: const Text('Sil'),
                    destructive: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
