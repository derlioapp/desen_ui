import 'dart:math' as math;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

/// Shows [child] under [theme] with the site's current settings (mode,
/// contrast, corners, density, selection style and platform) laid over it,
/// so a preview follows the settings menu like the rest of the page. Pass
/// `false` for a setting the preview sets itself.
class ThemePreview extends StatelessWidget {
  const ThemePreview({
    super.key,
    required this.theme,
    required this.child,
    this.followBrightness = true,
    this.followContrast = true,
    this.followCorners = true,
    this.followDensity = true,
    this.followPlatform = true,
    this.followSelection = true,
    this.animateChanges = false,
  });

  final DsThemeData theme;
  final Widget child;
  final bool followBrightness;
  final bool followContrast;
  final bool followCorners;
  final bool followDensity;
  final bool followPlatform;
  final bool followSelection;
  final bool animateChanges;

  @override
  Widget build(BuildContext context) {
    final site = DsTheme.of(context);
    final data = theme.copyWith(
      brightness: followBrightness ? site.brightness : null,
      contrast: followContrast ? site.contrast : null,
      cornerStyle: followCorners ? site.cornerStyle : null,
      density: followDensity ? site.density : null,
      platform: followPlatform ? site.platform : null,
      selectionStyle: followSelection ? site.selectionStyle : null,
    );
    return DsScope(
      theme: data,
      darkTheme: data,
      themeMode: data.isDark ? DsThemeMode.dark : DsThemeMode.light,
      followPlatformContrast: false,
      animateChanges: animateChanges,
      child: child,
    );
  }
}

/// Lays [children] out in equal columns at least [minWidth] wide.
class TokenGrid extends StatelessWidget {
  const TokenGrid({
    super.key,
    required this.children,
    this.minWidth = 168,
    this.spacing = 12,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double minWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = math.max(
        1,
        ((box.maxWidth + spacing) / (minWidth + spacing)).floor(),
      );
      final width = ((box.maxWidth - spacing * (columns - 1)) / columns)
          .floorToDouble();
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    },
  );
}

/// A framed area on the surface color, like the top of an [Example], for
/// live token boards that have no code under them.
class Board extends StatelessWidget {
  const Board({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Container(
      padding: padding,
      decoration: DsBoxDecoration(
        color: t.colors.surface,
        borderRadius: BorderRadius.circular(t.radii.card),
        shadows: [DsShadow.innerRing(t.colors.border)],
      ),
      child: child,
    );
  }
}

/// A small caption in the subtle text color.
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key, this.mono = false, this.color});

  final String text;
  final bool mono;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final y = t.typography;
    final style = mono ? y.mono(y.caption) : y.caption;
    return Text(
      text,
      style: style.copyWith(color: color ?? t.colors.textMuted),
    );
  }
}

/// `4.62:1`.
String ratioText(double r) => '${r.toStringAsFixed(r >= 10 ? 1 : 2)}:1';

/// `#2D4D8B`, with the opacity when the color is translucent.
String hexOf(Color c) {
  final rgb = (c.toARGB32() & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
  if (c.a >= 1) return '#$rgb';
  return '#$rgb · ${(c.a * 100).round()}%';
}

/// Reads `#RGB`, `#RRGGBB` or the same without `#`; null when it is not a
/// color.
Color? parseHex(String text) {
  var s = text.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) s = [for (final ch in s.split('')) '$ch$ch'].join();
  if (s.length != 6) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}
