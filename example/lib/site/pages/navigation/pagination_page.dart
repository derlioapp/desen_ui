import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class PaginationPage extends StatelessWidget {
  const PaginationPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Pagination',
    lead:
        'Moves through a long result split into pages, such as a table of '
        'records or search results. Put it under the content it pages, '
        'with the range of records shown next to it.',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            '`page` counts from 1. The current page takes the theme\'s '
            'selection style; numbers use tabular figures, so the row does '
            'not jump; the arrows turn inactive at the ends.',
          ),
          Example(snippet: 'pagination-overview', child: _TableFooterDemo()),
        ],
      ),
      const DocSection(
        title: 'Many pages',
        children: [
          DocText(
            'With more than seven pages, the row keeps the first and last '
            'page and the neighbors of the current one, with gaps between. '
            'It never shows more than seven slots, so it stays short.',
          ),
          Example(snippet: 'pagination-many', child: _ManyDemo()),
        ],
      ),
      const DocSection(
        title: 'Compact form',
        children: [
          DocText(
            'When the row does not fit its width, as on a phone, with touch '
            'density or with large text, it collapses to the arrows and '
            '"6 / 24". You do not choose the form; give the control the '
            'width it may use. This example is held to 200px.',
          ),
          Example(snippet: 'pagination-compact', child: _CompactDemo()),
        ],
      ),
      DocSection(
        title: 'No results',
        children: [
          const DocText(
            'With `pageCount: 0`, only the two inactive arrows show, and '
            '`page` is ignored. Keep the control in place so the layout does '
            'not shift when a filter empties the list.',
          ),
          Example(
            snippet: 'pagination-empty',
            // #region pagination-empty
            child: DsPagination(page: 1, pageCount: 0, onChanged: (p) {}),
            // #endregion
          ),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one control with `style`, or every one in a subtree with '
            '`DsPaginationTheme`. `itemSize` sets the square for each page; '
            '`selected` is the current page\'s look.',
          ),
          Example(snippet: 'pagination-custom', child: _CustomDemo()),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves through the arrows and pages; each one is a Tab stop. '
                  'Inactive arrows are skipped.',
            ),
            ('Enter / Space', 'Opens the focused page.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a navigation named "Pagination"; rename it with '
                '`semanticLabel`.',
            'Pages are read as "Page 4", and the current one as the current '
                'page. The compact form reads "Page 6 of 24".',
            'The arrows are named "Previous page" and "Next page"; '
                '`previousLabel` and `nextLabel` change them.',
            'Every built-in string follows the app\'s language.',
            'Each page and arrow keeps the platform\'s minimum tap area.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('page', 'int', 'The current page, from 1.'),
            ('pageCount', 'int', 'Number of pages; 0 for an empty result.'),
            (
              'onChanged',
              'ValueChanged<int>?',
              'Called with the chosen page. Null disables the control.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the navigation; defaults to "Pagination".',
            ),
            (
              'previousLabel / nextLabel',
              'String?',
              'Screen reader labels of the arrows.',
            ),
            (
              'style',
              'DsPaginationStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _TableFooterDemo extends StatefulWidget {
  const _TableFooterDemo();

  @override
  State<_TableFooterDemo> createState() => _TableFooterDemoState();
}

class _TableFooterDemoState extends State<_TableFooterDemo> {
  static const _total = 96, _perPage = 20;
  int _page = 2;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final from = (_page - 1) * _perPage + 1;
    final to = (_page * _perPage).clamp(0, _total);
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$from–$to of $_total invoices',
          style: t.typography
              .numeric(t.typography.small)
              .copyWith(color: t.colors.textMuted),
        ),
        // #region pagination-overview
        DsPagination(
          page: _page,
          pageCount: (_total / _perPage).ceil(),
          onChanged: (p) => setState(() => _page = p),
        ),
        // #endregion
      ],
    );
  }
}

class _ManyDemo extends StatefulWidget {
  const _ManyDemo();

  @override
  State<_ManyDemo> createState() => _ManyDemoState();
}

class _ManyDemoState extends State<_ManyDemo> {
  int _page = 6;

  @override
  Widget build(BuildContext context) =>
      // #region pagination-many
      DsPagination(
        page: _page,
        pageCount: 24,
        onChanged: (p) => setState(() => _page = p),
      );
  // #endregion
}

class _CompactDemo extends StatefulWidget {
  const _CompactDemo();

  @override
  State<_CompactDemo> createState() => _CompactDemoState();
}

class _CompactDemoState extends State<_CompactDemo> {
  int _page = 6;

  @override
  Widget build(BuildContext context) =>
      // #region pagination-compact
      SizedBox(
        width: 200,
        child: Center(
          child: DsPagination(
            page: _page,
            pageCount: 24,
            onChanged: (p) => setState(() => _page = p),
          ),
        ),
      );
  // #endregion
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  int _page = 3;

  @override
  Widget build(BuildContext context) =>
      // #region pagination-custom
      DsPagination(
        page: _page,
        pageCount: 5,
        onChanged: (p) => setState(() => _page = p),
        style: DsPaginationStyle(
          itemSize: 36,
          borderRadius: BorderRadius.circular(999),
          selected: const DsPaginationStyle(
            background: Color(0xFF0B6E4F),
            foreground: Color(0xFFFFFFFF),
          ),
        ),
      );
  // #endregion
}
