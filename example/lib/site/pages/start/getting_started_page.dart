import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

/// Installing Desen and the first screen.
class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Get started',
    title: 'Getting started',
    lead:
        'Add the package, wrap your app, and use the components. Desen needs '
        'Flutter 3.47 or later (Dart 3.13).',
    sections: [
      DocSection(
        title: 'Install',
        children: [
          DocText(
            'Desen is not on pub.dev yet; depend on it from a local path or '
            'a git checkout. Its typefaces, Schibsted Grotesk and Geist '
            'Mono, come with it.',
          ),
          CodeBlock(
            'dependencies:\n'
            '  desen_ui:\n'
            '    path: ../desen_ui',
            language: 'yaml',
          ),
        ],
      ),
      DocSection(
        title: 'A new app',
        children: [
          DocText(
            '`DsApp` sets up the theme, localization (13 languages), the '
            'navigator and the overlay that menus, popovers and dialogs '
            'need. Give it a brand color as the seed.',
          ),
          CodeBlock(
            "import 'package:desen_ui/desen_ui.dart';\n"
            "import 'package:flutter/widgets.dart';\n"
            '\n'
            'void main() => runApp(\n'
            '  DsApp(\n'
            '    theme: DsThemeData(seed: DsSeed.color(const Color(0xFF2D4D8B))),\n'
            '    themeMode: DsThemeMode.system,\n'
            '    home: const HomePage(),\n'
            '  ),\n'
            ');',
          ),
        ],
      ),
      DocSection(
        title: 'Inside an existing app',
        children: [
          DocText(
            '`DsScope` themes a subtree under any root, `MaterialApp` '
            'included. Layers (menus, selects, popovers, pickers, dialogs, '
            'toasts) need an `Overlay`, and dialogs and panels a '
            '`Navigator`; every `WidgetsApp` provides both.',
          ),
          CodeBlock(
            'DsScope(\n'
            '  theme: DsThemeData(seed: DsSeed.navy),\n'
            '  themeMode: DsThemeMode.system,\n'
            '  child: child,\n'
            ')',
          ),
        ],
      ),
      DocSection(
        title: 'Use the components',
        children: [
          CodeBlock(
            "DsField(\n"
            "  label: const Text('Email'),\n"
            "  child: DsTextField(onChanged: (v) => email = v),\n"
            ")\n"
            "DsButton(onPressed: save, child: const Text('Save'))\n"
            "DsButton(variant: .secondary, onPressed: cancel, child: const Text('Cancel'))",
          ),
          DocText(
            'Read the theme with `DsTheme.of(context)`, or just its colors '
            'with `DsTheme.colorsOf(context)`, which rebuilds only when '
            'colors change. Continue with [Theming](/theming).',
          ),
        ],
      ),
    ],
  );
}
