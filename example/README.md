# Desen UI example

A first screen with Desen: a field and a button in a `DsApp`.

```dart
import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(
  DsApp(
    theme: DsThemeData(seed: DsSeed.navy),
    home: const HomePage(),
  ),
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return ColoredBox(
      color: t.colors.canvas,
      child: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const DsField(label: Text('Email'), child: DsTextField()),
              DsButton(
                onPressed: () =>
                    showDsToast(context: context, title: 'Saved'),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Every component, with live examples and their code, is on the docs site: https://derlioapp.github.io/desen_ui/

## The docs site

This folder is that site, built with Desen itself. Run it with:

```bash
flutter run -d chrome
```

- Pages live in `lib/site/pages/<group>/`, registered in each group's `index.dart`.
- The code under an example comes from `// #region` markers in the page's own source; regenerate it with `python3 tool/gen_snippets.py` from the repository root (the `tool/` folder is in the repository, not in the published package).
- `test/site_pages_test.dart` opens every page at 390, 768, 1280 and 1600px in light and dark; `test/site_links_test.dart` checks internal links.
- `?tone=Navy&mode=dark&contrast=soft&lang=ar` presets the settings, for screenshots.
