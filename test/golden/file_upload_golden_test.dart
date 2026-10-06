@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the file upload: the drop zone idle,
/// dragged over and in error, and a file row in each state, light and dark.
/// Turkish strings and sizes, with a comma as the decimal separator.
void main() {
  Widget zones() => SizedBox(
    width: 380,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        DsFileUpload(
          onBrowse: () {},
          description: const Text('PDF, PNG · en fazla 10 MB'),
        ),
        DsFileUpload(
          onBrowse: () {},
          dragging: true,
          description: const Text('PDF, PNG · en fazla 10 MB'),
        ),
        DsField(
          label: const Text('Ekler'),
          errorText: 'En az bir dosya ekleyin.',
          required: true,
          child: DsFileUpload(
            onBrowse: () {},
            description: const Text('PDF, PNG · en fazla 10 MB'),
          ),
        ),
        const DsFileUpload(
          onBrowse: null,
          description: Text('PDF, PNG · en fazla 10 MB'),
        ),
      ],
    ),
  );

  Widget rows() => SizedBox(
    width: 380,
    child: DsFileUpload(
      onBrowse: () {},
      description: const Text('PDF, PNG · en fazla 10 MB'),
      files: [
        DsFileItem(
          name: 'sunum-v3.pdf',
          size: 3100000,
          status: DsFileStatus.uploading,
          progress: .78,
          onCancel: () {},
        ),
        DsFileItem(name: 'kapak.png', size: 840000, onRemove: () {}),
        DsFileItem(
          name: 'rapor-2025.xlsx',
          status: DsFileStatus.error,
          message: 'Desteklenmeyen dosya türü',
          onRetry: () {},
          onRemove: () {},
        ),
        DsFileItem(
          name: 'cok-uzun-bir-dosya-adi-ile-arsiv-yedegi-2025-final.zip',
          size: 1250000000,
          status: DsFileStatus.uploading,
          progress: .12,
          onCancel: () {},
        ),
      ],
    ),
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('file upload $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        Localizations(
          locale: const Locale('tr'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 32,
            children: [zones(), rows()],
          ),
        ),
      );
      await expectGolden(tester, 'goldens/file_upload_$mode.png');
    });
  }
}
