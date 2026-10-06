import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import '../../shell.dart' show pageAt;

/// The window an example screen sits in: the app canvas, the card radius
/// and a hairline edge drawn over the content, so a sidebar or a header
/// running to the edge keeps the frame's outline.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.label, required this.child});

  /// Names the screen for screen readers ("Northwind dashboard").
  final String label;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final radius = BorderRadius.circular(t.radii.card);
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Container(
        decoration: DsBoxDecoration(
          color: k.canvas,
          borderRadius: radius,
          shadows: t.shadows.surface,
        ),
        foregroundDecoration: DsBoxDecoration(
          borderRadius: radius,
          shadows: [DsShadow.innerRing(k.border)],
        ),
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}

/// "Built with …": the components a screen uses, each linked to its page
/// once the page exists.
class BuiltWith extends StatelessWidget {
  const BuiltWith(this.components, {super.key});

  /// (name, site path) pairs, in reading order.
  final List<(String, String)> components;

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final (name, path) in components)
        pageAt(path) == null ? name : '[$name]($path)',
    ];
    final list = names.length < 2
        ? names.join()
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    return DocText('This screen uses $list.');
  }
}
