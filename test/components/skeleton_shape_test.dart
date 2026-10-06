import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Skeleton corners: text lines are fully rounded, circles are round, and
/// blocks (an image, a card, a button) take the radius of media in a card
/// (the card radius less its padding), like the content they stand in for.
void main() {
  BorderRadius corners(WidgetTester tester, Finder skeleton) {
    final box = tester.widget<Container>(
      find.descendant(of: skeleton, matching: find.byType(Container)),
    );
    return (box.decoration! as DsBoxDecoration).borderRadius.resolve(
      TextDirection.ltr,
    );
  }

  for (final style in DsCornerStyle.values) {
    testWidgets('lines, circles and blocks (${style.name} corners)', (
      tester,
    ) async {
      final theme = DsThemeData(cornerStyle: style);
      final block = theme.radii.nested(theme.radii.card, DsSpace.s16);
      await tester.pumpWidget(
        host(
          theme: theme,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsSkeleton(key: Key('line'), width: 200),
              DsSkeleton(key: Key('title'), width: 120, height: 14),
              DsSkeleton.circle(key: Key('circle'), size: 40),
              DsSkeleton(key: Key('image'), width: 200, height: 120),
              DsSkeleton.block(key: Key('button'), width: 96, height: 32),
              DsSkeleton.block(key: Key('chip'), width: 40, height: 6),
            ],
          ),
        ),
      );
      Radius of(String key) => corners(tester, find.byKey(Key(key))).topLeft;
      expect(of('line'), const Radius.circular(4));
      expect(of('title'), const Radius.circular(7));
      expect(of('circle'), const Radius.circular(20));
      expect(of('image'), Radius.circular(block));
      expect(of('button'), Radius.circular(block.clamp(0, 16)));
      // Never rounder than a capsule.
      expect(of('chip'), Radius.circular(block.clamp(0, 3)));
    });
  }

  testWidgets('a style still sets the corners', (tester) async {
    await tester.pumpWidget(
      host(
        const DsSkeleton(
          width: 200,
          height: 120,
          style: DsSkeletonStyle(borderRadius: BorderRadius.zero),
        ),
      ),
    );
    expect(corners(tester, find.byType(DsSkeleton)), BorderRadius.zero);
  });
}
