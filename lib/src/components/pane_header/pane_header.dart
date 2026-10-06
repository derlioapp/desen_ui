import 'package:flutter/widgets.dart';

import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../link/breadcrumb.dart';
import 'pane_header_style.dart';

/// The header of a pane: where you are on the start side, actions on the
/// end side, and a hairline between it and the content.
///
/// ```dart
/// DsPaneHeader(
///   title: DsBreadcrumb(items: [...]),
///   actions: [
///     DsButton.icon(icon: const DsIcon(DsIcons.share), semanticLabel: 'Paylaş', onPressed: share),
///     DsButton(variant: .primary, size: .sm, onPressed: publish, child: const Text('Yayınla')),
///   ],
/// )
/// ```
class DsPaneHeader extends StatelessWidget {
  /// Creates a pane header.
  const DsPaneHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.style,
  });

  /// Usually a [DsBreadcrumb] or a [Text]. Takes the remaining width and
  /// keeps to one line: text in it is ellipsized (the ambient
  /// [DefaultTextStyle] allows one line), and a [DsBreadcrumb] collapses
  /// its middle levels into a "…" menu instead of wrapping
  /// ([DsBreadcrumbOverflow.collapse]).
  final Widget title;

  /// Buttons on the end side.
  final List<Widget> actions;

  /// Style laid over the theme and defaults.
  final DsPaneHeaderStyle? style;

  /// Desen's default pane header style under [theme].
  static DsPaneHeaderStyle defaultStyle(DsThemeData theme) => DsPaneHeaderStyle(
    height: 52,
    padding: const EdgeInsetsDirectional.only(
      start: DsSpace.s16,
      end: DsSpace.s12,
    ),
    dividerColor: theme.colors.border,
    gap: DsSpace.s8,
  );

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsPaneHeaderStyle.resolveLayers([
      defaultStyle(t),
      DsPaneHeaderTheme.of(context).style,
      style,
    ], const {});
    return Semantics(
      container: true,
      header: true,
      child: Container(
        constraints: BoxConstraints(minHeight: s.height!),
        padding: s.padding,
        decoration: DsBoxDecoration(
          color: s.background,
          shadows: [
            if (s.dividerColor case final line?)
              DsShadow.bottomLine(line, hairline: true),
          ],
        ),
        child: Row(
          spacing: s.gap ?? DsSpace.s8,
          children: [
            // One line: a Text ellipsizes, a breadcrumb collapses.
            Expanded(
              child: DefaultTextStyle.merge(
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: title,
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
