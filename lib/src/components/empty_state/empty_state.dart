import 'package:flutter/widgets.dart';

import '../../painting/decoration.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'empty_state_style.dart';

/// An empty state: a tone disk with an icon, a title, a short description
/// and actions. Place it in a card or an empty pane.
///
/// ```dart
/// DsEmptyState(
///   icon: const DsIcon(DsIcons.inbox),
///   title: const Text('Henüz görev yok'),
///   description: const Text('İlk görevi ekleyin ya da bir şablonla başlayın.'),
///   actions: [
///     DsButton(variant: .primary, size: .sm, onPressed: add, child: const Text('Görev ekle')),
///     DsButton(variant: .ghost, size: .sm, onPressed: templates, child: const Text('Şablonlar')),
///   ],
/// )
/// ```
class DsEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const DsEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.actions = const [],
    this.style,
  });

  /// Shown in the tone disk, usually a [DsIcon].
  final Widget? icon;

  /// What is empty, as an invitation ("Henüz görev yok").
  final Widget title;

  /// One or two sentences on what to do next.
  final Widget? description;

  /// Buttons: at most one primary.
  final List<Widget> actions;

  /// Style laid over the theme and defaults.
  final DsEmptyStateStyle? style;

  /// Desen's default empty state style under [theme].
  static DsEmptyStateStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const iconBox = 48.0;
    return DsEmptyStateStyle(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.s24,
        vertical: DsSpace.s28,
      ),
      iconBoxSize: iconBox,
      iconBoxColor: k.accentTint,
      // No radius: the corners follow the resolved box size.
      iconColor: k.accentText,
      iconSize: 20,
      titleStyle: theme.typography.heading.copyWith(color: k.text),
      descriptionStyle: theme.typography.body.copyWith(color: k.textMuted),
      descriptionMaxWidth: 280,
      gap: DsSpace.s16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsEmptyStateStyle.resolveLayers([
      defaultStyle(t),
      DsEmptyStateTheme.of(context).style,
      style,
    ], const {});
    final box = s.iconBoxSize!;
    return Padding(
      padding: s.padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: s.gap ?? DsSpace.s16,
        children: [
          if (icon != null)
            ExcludeSemantics(
              child: Container(
                width: box,
                height: box,
                alignment: Alignment.center,
                decoration: DsBoxDecoration(
                  color: s.iconBoxColor,
                  borderRadius: t.radii.controlCorners(s.iconBoxRadius, box),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: s.iconColor, size: s.iconSize),
                  child: icon!,
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: DsSpace.s4,
            children: [
              Semantics(
                header: true,
                child: DefaultTextStyle.merge(
                  style: s.titleStyle,
                  textAlign: TextAlign.center,
                  child: title,
                ),
              ),
              if (description != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: s.descriptionMaxWidth ?? double.infinity,
                  ),
                  child: DefaultTextStyle.merge(
                    style: s.descriptionStyle,
                    textAlign: TextAlign.center,
                    child: description!,
                  ),
                ),
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(
              spacing: DsSpace.s8,
              runSpacing: DsSpace.s8,
              alignment: WrapAlignment.center,
              children: actions,
            ),
        ],
      ),
    );
  }
}
