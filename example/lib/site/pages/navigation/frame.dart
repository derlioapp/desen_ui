import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

/// A small app window for navigation examples: a sidebar on the start side
/// and a content pane that hides when the window is too narrow for both.
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.sidebar,
    required this.title,
    this.height = 340,
  });

  final Widget sidebar;
  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final radius = BorderRadius.circular(t.radii.card);
    return LayoutBuilder(
      builder: (context, c) => Container(
        height: height,
        decoration: DsBoxDecoration(
          color: k.surface,
          borderRadius: radius,
          shadows: t.shadows.surface,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (c.maxWidth >= 440) sidebar else Expanded(child: sidebar),
              if (c.maxWidth >= 440)
                Expanded(child: ContentSketch(title: title)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page title over skeleton lines: content that is not the point.
class ContentSketch extends StatelessWidget {
  const ContentSketch({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.typography.heading.copyWith(color: t.colors.text),
          ),
          const FractionallySizedBox(
            widthFactor: .9,
            child: DsSkeleton(strong: true),
          ),
          const FractionallySizedBox(widthFactor: .7, child: DsSkeleton()),
          const FractionallySizedBox(widthFactor: .8, child: DsSkeleton()),
          const FractionallySizedBox(widthFactor: .5, child: DsSkeleton()),
        ],
      ),
    );
  }
}

/// A phone-sized screen: content behind, [bar] at the bottom.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.title,
    required this.bar,
    this.floating = true,
  });

  final String title;
  final Widget bar;

  /// A floating bar sits above the bottom edge, centered; a full-width bar
  /// runs along the edge, over a home indicator area.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final radius = BorderRadius.circular(28);
    return Container(
      width: 300,
      height: 400,
      decoration: DsBoxDecoration(
        color: k.canvas,
        borderRadius: radius,
        shadows: [DsShadow.innerRing(k.border), ...t.shadows.surface],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(child: ContentSketch(title: title)),
            ),
            Positioned(
              left: floating ? 12 : 0,
              right: floating ? 12 : 0,
              bottom: floating ? 20 : 0,
              child: floating
                  ? Center(child: bar)
                  // The home indicator area under a full-width bar.
                  : MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(padding: const EdgeInsets.only(bottom: 20)),
                      child: bar,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
