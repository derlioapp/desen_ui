import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The file upload page: a drop zone and a row per file.
class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'File upload',
    lead:
        'A drop zone for files, with a row per file that shows its upload. '
        'Desen draws the zone and the rows; your app picks the files, '
        'receives drops and sends them, so the library needs no plugin.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          const Callout(
            'A web page cannot read files from your disk without a picker '
            'plugin, and this site uses none. In these examples "browse" '
            'adds fake files and a timer plays their progress. One of them '
            'fails halfway so you can retry it.',
            title: 'Simulated files',
          ),
          Example(snippet: 'file-upload-overview', child: const _UploadDemo()),
        ],
      ),
      DocSection(
        title: 'Picking and dropping files',
        children: [
          const DocText(
            'A click on the zone, or Enter or Space when it has focus, calls '
            '`onBrowse`. Open your file picker there, such as the '
            '`file_picker` package. For drops, wrap the zone in the drop '
            'target of your platform plugin and set `dragging` while files '
            'are over it:',
          ),
          const DocList([
            '**desktop_drop:** a `DropTarget` around the zone; set '
                '`dragging` in `onDragEntered` and `onDragExited`, upload in '
                '`onDragDone`.',
            '**super_drag_and_drop:** a `DropRegion`; set `dragging` in '
                '`onDropEnter` and `onDropLeave`, read the files in '
                '`onPerformDrop`.',
            '**Web without a plugin:** listen to `dragenter`, `dragleave` '
                'and `drop` with `package:web` and hit-test the pointer '
                'against the zone.',
          ]),
          const DocText(
            'While `dragging`, the edge takes the accent, the zone a tint, '
            'and the prompt says to drop. Turn on the switch to see it.',
          ),
          Example(
            snippet: 'file-upload-dragging',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  // #region file-upload-dragging
                  DsFileUpload(
                    onBrowse: () {},
                    dragging: _dragging,
                    description: const Text('PNG or JPG · up to 5 MB'),
                  ),
                  DsSwitch(
                    value: _dragging,
                    onChanged: (v) => setState(() => _dragging = v),
                    label: const Text('Files over the zone'),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Accepted types and size',
        children: [
          const DocText(
            'Say what is accepted in the `description`, and check each file '
            'yourself when it arrives: the zone does not filter. Reject a '
            'file before it uploads through the `DsField`\'s `errorText`, '
            'which gives the zone a 2px error edge and is announced. Format '
            'sizes with `dsFormatFileSize`, which follows the language '
            '("2.4 MB", "2,4 MB").',
          ),
          Example(snippet: 'file-upload-accept', child: const _AcceptDemo()),
        ],
      ),
      DocSection(
        title: 'File rows',
        children: [
          const DocText(
            '`DsFileItem` shows one file in one of three states. While '
            '`uploading` it shows a progress bar, the amount sent and the '
            'percentage; a null `progress` shows an indeterminate bar. '
            'When `done` it shows a success icon and the size. On `error` '
            'it shows a 2px error edge, the error icon and the `message`. '
            'Each callback adds its button: `onCancel` while uploading, '
            '`onRetry` on error, `onRemove` when done or failed.',
          ),
          Example(
            snippet: 'file-upload-items',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  // #region file-upload-items
                  DsFileItem(
                    name: 'brand-guidelines.pdf',
                    size: 3100000,
                    status: DsFileStatus.uploading,
                    progress: .42,
                    onCancel: () {},
                  ),
                  DsFileItem(
                    name: 'export.csv',
                    status: DsFileStatus.uploading,
                    onCancel: () {},
                  ),
                  DsFileItem(
                    name: 'cover.png',
                    size: 840000,
                    status: DsFileStatus.done,
                    onRemove: () {},
                  ),
                  DsFileItem(
                    name: 'q3-report.xlsx',
                    size: 1800000,
                    status: DsFileStatus.error,
                    message: 'The connection was lost.',
                    onRetry: () {},
                    onRemove: () {},
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Disabled',
        children: [
          const DocText(
            'A null `onBrowse` disables the zone: no focus, no hover, the '
            'disabled fill and faint ink. The rows below it stay as they '
            'are, so people can still see and remove what was uploaded.',
          ),
          Example(
            snippet: 'file-upload-disabled',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // #region file-upload-disabled
              child: DsField(
                label: const Text('Attachments'),
                description: const Text('The limit of 3 files is reached.'),
                child: DsFileUpload(
                  onBrowse: null,
                  files: [
                    for (final (name, size) in const [
                      ('floor-plan.pdf', 2400000),
                      ('photo-1.jpg', 1200000),
                      ('photo-2.jpg', 980000),
                    ])
                      DsFileItem(name: name, size: size, onRemove: () {}),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Dashed border',
        children: [
          const DocText(
            'The zone\'s edge is a `DsDashedBorder`, and you can use it on '
            'its own, for example around an empty slot. The dashes are '
            'spread evenly, so the pattern closes cleanly around rounded '
            'corners. The stroke sits inside the box and takes no '
            'pointers.',
          ),
          Example(
            snippet: 'file-upload-dashed',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              // #region file-upload-dashed
              child: DsDashedBorder(
                color: DsTheme.of(context).colors.borderControl,
                width: 1.5,
                dashLength: 6,
                dashGap: 4,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 96,
                  child: Center(
                    child: DsButton(
                      variant: .ghost,
                      leading: const DsIcon(DsIcons.plus),
                      onPressed: () {},
                      child: const Text('Add widget'),
                    ),
                  ),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change the zone with `style` or `DsFileUploadTheme`, and the '
            'rows with their own `style` or `DsFileItemTheme`; '
            '`DsComponentThemes` sets both app-wide. The zone\'s states '
            'nest as `hovered`, `focused`, `selected` (dragging), `error` '
            'and `disabled`.',
          ),
          Example(
            snippet: 'file-upload-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // #region file-upload-custom
              child: DsFileUpload(
                onBrowse: () {},
                description: const Text('SVG or PNG · at least 512 × 512 px'),
                title: const Text('Upload your logo'),
                style: DsFileUploadStyle(
                  height: 140,
                  borderRadius: BorderRadius.circular(20),
                  dashLength: 2,
                  dashGap: 4,
                  iconColor: const Color(0xFF0B6E4F),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Moves to the zone, then to each row\'s buttons.'),
            ('Enter / Space', 'On the zone: calls `onBrowse`.'),
            ('Enter / Space', 'On a row button: cancels, retries or removes.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The zone is one button named by the `DsField` label, the '
                'prompt and the description; `semanticLabel` replaces that.',
            'The files below are read as a list. Each row says the file '
                'name with its state ("cover.png uploaded, 840 KB") and the '
                'progress bar\'s value.',
            'The cancel, retry and remove buttons are named with the file '
                '("Remove cover.png", "Retry upload of cover.png"). The retry '
                'button shows "Retry", and its name holds that visible word '
                'in every language, so voice control finds it.',
            'A change to done or failed is announced politely.',
            'Errors are not told by color alone: a thicker edge, an icon '
                'and a message.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsFileUpload'),
          ApiTable([
            (
              'onBrowse',
              'VoidCallback?',
              'Opens your file picker. Null disables the zone.',
            ),
            (
              'files',
              'List<Widget>',
              'The rows below the zone, usually `DsFileItem`s.',
            ),
            (
              'dragging',
              'bool',
              'Files are over the zone; set it from your drop target.',
            ),
            (
              'description',
              'Widget?',
              'A line under the prompt: types and size.',
            ),
            ('title', 'Widget?', 'Replaces "Drop files here or browse".'),
            ('icon', 'Widget?', 'Replaces the upload icon.'),
            (
              'error',
              'bool',
              'The error look; a `DsField` with an error sets it too.',
            ),
            (
              'semanticLabel',
              'String?',
              'Replaces what screen readers hear for the zone.',
            ),
            (
              'style',
              'DsFileUploadStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
          DocHeading('DsFileItem'),
          ApiTable([
            ('name', 'String', 'The file name.'),
            (
              'status',
              'DsFileStatus',
              '`uploading`, `done` (default) or `error`.',
            ),
            ('size', 'int?', 'The size in bytes.'),
            (
              'progress',
              'double?',
              'From 0 to 1 while uploading; null for an indeterminate bar.',
            ),
            (
              'message',
              'String?',
              'Why it failed; defaults to "Upload failed".',
            ),
            (
              'onCancel / onRetry / onRemove',
              'VoidCallback?',
              'Each adds its button in the states it applies to.',
            ),
            ('style', 'DsFileItemStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

/// One simulated upload.
class _Upload {
  _Upload(this.name, this.size, {this.fails = false});

  final String name;
  final int size;

  /// Fails at 60% the first time, to show the error row and retry.
  bool fails;
  double progress = 0;
  DsFileStatus status = DsFileStatus.uploading;
  String? error;
}

/// A drop zone with simulated uploads: "browse" adds the next sample file,
/// a timer drives the progress, one file fails and can be retried.
class _UploadDemo extends StatefulWidget {
  const _UploadDemo();

  @override
  State<_UploadDemo> createState() => _UploadDemoState();
}

class _UploadDemoState extends State<_UploadDemo> {
  static const _samples = [
    ('kickoff-slides.pdf', 3100000, false),
    ('budget-2027.xlsx', 1800000, true),
    ('hero-image.png', 840000, false),
    ('meeting-notes.pdf', 420000, false),
    ('screenshot.png', 2600000, false),
  ];

  final _uploads = <_Upload>[
    _Upload('logo.png', 640000)
      ..progress = 1
      ..status = DsFileStatus.done,
  ];
  int _next = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Stands in for a file picker: adds the next sample file.
  void _browse() {
    final (name, size, fails) = _samples[_next % _samples.length];
    _next++;
    setState(() => _uploads.insert(0, _Upload(name, size, fails: fails)));
    _run();
  }

  void _run() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 120), (_) {
      var active = false;
      setState(() {
        for (final u in _uploads) {
          if (u.status != DsFileStatus.uploading) continue;
          // Bigger files move slower.
          u.progress += 0.12 * 1000000 / (u.size + 400000);
          if (u.fails && u.progress >= .6) {
            u
              ..status = DsFileStatus.error
              ..error = 'The connection was lost.';
          } else if (u.progress >= 1) {
            u
              ..progress = 1
              ..status = DsFileStatus.done;
          } else {
            active = true;
          }
        }
      });
      if (!active) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void _retry(_Upload u) {
    setState(() {
      u
        ..fails = false
        ..progress = 0
        ..error = null
        ..status = DsFileStatus.uploading;
    });
    _run();
  }

  void _remove(_Upload u) => setState(() => _uploads.remove(u));

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    // #region file-upload-overview
    child: DsField(
      label: const Text('Attachments'),
      child: DsFileUpload(
        onBrowse: _browse,
        description: const Text('PDF, PNG or XLSX · up to 10 MB'),
        files: [
          for (final u in _uploads)
            DsFileItem(
              key: ObjectKey(u),
              name: u.name,
              size: u.size,
              status: u.status,
              progress: u.progress,
              message: u.error,
              onCancel: () => _remove(u),
              onRemove: () => _remove(u),
              onRetry: () => _retry(u),
            ),
        ],
      ),
    ),
    // #endregion
  );
}

/// A zone that rejects what the pretend picker returns, to show the
/// field's error. Built under the example's language, so the size is
/// formatted in it.
class _AcceptDemo extends StatefulWidget {
  const _AcceptDemo();

  @override
  State<_AcceptDemo> createState() => _AcceptDemoState();
}

class _AcceptDemoState extends State<_AcceptDemo> {
  String? _rejected;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    // #region file-upload-accept
    child: DsField(
      label: const Text('Receipt'),
      errorText: _rejected,
      child: DsFileUpload(
        description: const Text('PDF, PNG or JPG · up to 10 MB'),
        onBrowse: () {
          // Stands in for a picker that returned a large video.
          const name = 'site-visit.mov', bytes = 48200000;
          final size = dsFormatFileSize(
            bytes,
            locale: Localizations.localeOf(context),
          );
          setState(() => _rejected = '$name is $size. The limit is 10 MB.');
        },
      ),
    ),
    // #endregion
  );
}
