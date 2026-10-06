# Desen UI docs site

The documentation site of Desen UI, built with Desen itself: every component with live examples and their code, foundations, guides and realistic app screens.

```bash
flutter run -d chrome
```

- Pages live in `lib/site/pages/<group>/`, registered in each group's `index.dart`.
- The code under an example comes from `// #region` markers in the page's own source; regenerate with `python3 tool/gen_snippets.py` (from the repository root).
- `test/site_pages_test.dart` opens every page at 390, 768, 1280 and 1600px in light and dark; `test/site_links_test.dart` checks internal links.
- `?tone=Navy&mode=dark&contrast=high&lang=ar` presets the settings, for screenshots.
