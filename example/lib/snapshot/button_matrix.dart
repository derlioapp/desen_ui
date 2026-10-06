import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

/// Every DsButton variant in every state, with states forced through a
/// statesController so they can be compared side by side.
class ButtonMatrix extends StatelessWidget {
  const ButtonMatrix({super.key});

  static const _columns = <(String, Set<WidgetState>)>[
    ('Normal', {}),
    ('Hover', {WidgetState.hovered}),
    ('Odak', {WidgetState.focused}),
    ('Basılı', {WidgetState.pressed}),
  ];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final caption = t.typography
        .mono(t.typography.caption)
        .copyWith(color: t.colors.textSubtle);
    Widget cell(Widget child) =>
        SizedBox(width: 132, height: 56, child: Center(child: child));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 96),
            for (final (label, _) in _columns)
              cell(Text(label, style: caption)),
            cell(Text('Pasif', style: caption)),
            cell(Text('Yükleniyor', style: caption)),
          ],
        ),
        for (final variant in DsButtonVariant.values)
          Row(
            children: [
              SizedBox(width: 96, child: Text(variant.name, style: caption)),
              for (final (_, states) in _columns)
                cell(
                  DsButton(
                    variant: variant,
                    statesController: WidgetStatesController(states),
                    onPressed: () {},
                    child: const Text('Kaydet'),
                  ),
                ),
              cell(
                DsButton(
                  variant: variant,
                  onPressed: null,
                  child: const Text('Kaydet'),
                ),
              ),
              cell(
                DsButton(
                  variant: variant,
                  loading: true,
                  onPressed: () {},
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
