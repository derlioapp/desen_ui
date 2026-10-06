import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';

/// A ready-made brand tone the site can switch to.
class SiteTone {
  const SiteTone(this.name, this.seed, this.note);

  final String name;
  final DsSeed seed;

  /// What the palette engine does with it, in one line.
  final String note;
}

const siteTones = <SiteTone>[
  SiteTone(
    'Blue',
    DsSeed.blue,
    'The default: the most vivid blue that carries a white label at AA.',
  ),
  SiteTone('Navy', DsSeed.navy, 'A dark, matte brand blue.'),
  SiteTone(
    'Graphite',
    DsSeed.graphite,
    'A neutral primary: selection is a mid gray with full-ink text.',
  ),
  SiteTone(
    'Oxblood',
    DsSeed.oxblood,
    'Close to danger: danger shifts toward tomato so the two stay apart. '
        'In dark mode, selection is a clear gray, not a muddy dark red.',
  ),
  SiteTone(
    'Forest',
    DsSeed.forest,
    'Close to success: success shifts toward leaf green. In dark mode, '
        'selection is a clear gray.',
  ),
  SiteTone('Indigo', DsSeed.indigo, 'A vivid accent with more energy.'),
  SiteTone(
    'Yellow',
    // #FFC72C, a light brand color.
    DsSeed.oklch(.857, .165, 87),
    'A light brand color: dark labels on the fill, darkened ink for links '
        'and focus.',
  ),
];

/// Everything a visitor can change, applied to the whole site.
@immutable
class SiteSettings {
  const SiteSettings({
    this.tone = 0,
    this.mode = DsThemeMode.system,
    this.contrast = DsContrast.standard,
    this.corners = DsCornerStyle.standard,
    this.density = DsDensity.compact,
    this.selection = DsSelectionStyle.soft,
    this.previewLocale = const Locale('en'),
  });

  /// Index into [siteTones].
  final int tone;
  final DsThemeMode mode;
  final DsContrast contrast;
  final DsCornerStyle corners;
  final DsDensity density;
  final DsSelectionStyle selection;

  /// The language of the components in examples (their built-in strings,
  /// date formats and direction). The site's own text stays English.
  final Locale previewLocale;

  SiteSettings copyWith({
    int? tone,
    DsThemeMode? mode,
    DsContrast? contrast,
    DsCornerStyle? corners,
    DsDensity? density,
    DsSelectionStyle? selection,
    Locale? previewLocale,
  }) => SiteSettings(
    tone: tone ?? this.tone,
    mode: mode ?? this.mode,
    contrast: contrast ?? this.contrast,
    corners: corners ?? this.corners,
    density: density ?? this.density,
    selection: selection ?? this.selection,
    previewLocale: previewLocale ?? this.previewLocale,
  );

  DsThemeData theme() => DsThemeData(
    seed: siteTones[tone].seed,
    contrast: contrast,
    cornerStyle: corners,
    density: density,
    selectionStyle: selection,
  );

  /// Reads `?tone=Navy&mode=dark&contrast=soft&density=touch&lang=ar`
  /// (contrast `soft` or `standard`, anything else is standard; density
  /// `compact` or `touch`, otherwise the platform's, as a theme without one
  /// takes), for repeatable screenshots and links.
  static SiteSettings fromQuery(Map<String, String> q) {
    final tone = siteTones.indexWhere(
      (t) => t.name.toLowerCase() == q['tone']?.toLowerCase(),
    );
    return SiteSettings(
      tone: tone < 0 ? 0 : tone,
      mode: switch (q['mode']) {
        'dark' => DsThemeMode.dark,
        'light' => DsThemeMode.light,
        _ => DsThemeMode.system,
      },
      contrast: DsContrast.values.firstWhere(
        (c) => c.name == q['contrast'],
        orElse: () => DsContrast.standard,
      ),
      density: DsDensity.values.firstWhere(
        (d) => d.name == q['density'],
        orElse: () => DsDensity.forPlatform(defaultTargetPlatform),
      ),
      previewLocale: q['lang'] == null
          ? const Locale('en')
          : Locale(q['lang']!),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SiteSettings &&
      other.tone == tone &&
      other.mode == mode &&
      other.contrast == contrast &&
      other.corners == corners &&
      other.density == density &&
      other.selection == selection &&
      other.previewLocale == previewLocale;

  @override
  int get hashCode => Object.hash(
    tone,
    mode,
    contrast,
    corners,
    density,
    selection,
    previewLocale,
  );
}

/// The language names shown in the preview-language picker, in their own
/// language.
const previewLanguages = <String, String>{
  'en': 'English',
  'tr': 'Türkçe',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'it': 'Italiano',
  'pt': 'Português (Brasil)',
  'pt_PT': 'Português (Portugal)',
  'ru': 'Русский',
  'ar': 'العربية',
  'hi': 'हिन्दी',
  'ja': '日本語',
  'ko': '한국어',
  'zh': '简体中文',
  'zh_Hant': '繁體中文',
};

Locale previewLocaleOf(String key) {
  final parts = key.split('_');
  if (parts.length == 1) return Locale(parts.first);
  return parts[1].length == 4
      ? Locale.fromSubtags(languageCode: parts.first, scriptCode: parts[1])
      : Locale(parts.first, parts[1]);
}

String previewLocaleKey(Locale l) =>
    [l.languageCode, ?l.scriptCode, ?l.countryCode].join('_');

/// The settings and a way to change them.
class SiteSettingsScope extends InheritedWidget {
  const SiteSettingsScope({
    super.key,
    required this.settings,
    required this.onChanged,
    required super.child,
  });

  final SiteSettings settings;
  final ValueChanged<SiteSettings> onChanged;

  static SiteSettingsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteSettingsScope>()!;

  @override
  bool updateShouldNotify(SiteSettingsScope old) => old.settings != settings;
}
