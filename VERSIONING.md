# Versioning policy

Desen UI follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.
This page says what each part means for a UI library, where "the API" is more
than Dart signatures: theme tokens and the default look are part of what an
app depends on.

## What a change is

| Change | Kind | Example |
|---|---|---|
| Remove or rename a public class, constructor, parameter, enum value, style field or theme token | **Breaking** | `DsContrast.high` removed |
| Change a parameter's type, make an optional parameter required, change a default *behavior* (what a widget does, announces or accepts) | **Breaking** | a callback that fires at a different moment |
| Change what a style field or token *means*, so code that sets it gets a different result | **Breaking** | a width that starts counting outside the box |
| Raise the minimum Flutter or Dart SDK | **Minor**, noted in the changelog | `flutter: ">=3.47.0"` → a later stable |
| Add a class, parameter, style field, token, enum value or component | **Minor** | `DsShadow(hairline: true)` |
| Change the default look: a color, a radius, a shadow, a spacing, a font size, a motion curve | **Minor**, with a changelog entry under *Changed* | dark-mode `channelThumb` becomes translucent |
| Fix a bug without changing documented behavior; docs; performance | **Patch** | a focus ring drawn 1px off |

Notes:

- **The default look is not frozen.** Desen keeps improving contrast, spacing
  and motion. A visual change never needs code changes in an app, so it is
  minor, not major. It is always listed under *Changed* in `CHANGELOG.md`,
  so apps with their own golden tests know why a golden moved. Pin an exact
  version if your goldens must not move.
- **Adding an enum value is minor.** Exhaustive `switch`es over Desen enums
  in app code may need a new case; this is accepted, as in Flutter itself.
- **Adding a field to a style class is minor.** Style classes are meant to be
  built with named arguments and `merge`d, not implemented or extended.
  Token constructors documented as "meant for tests and tools" (`DsColors`,
  `DsRadii`, `DsSizes`, `DsShadows`, `DsThemeData.raw`) are outside the
  promise: they may gain required values in a minor release.
- **Anything under `lib/src/` that `package:desen_ui/desen_ui.dart` does not
  export is private.** Importing it is not supported.
- **Accessibility fixes win.** If a default fails WCAG AA or misreports a
  role or state to screen readers, it is fixed in a patch or minor release
  even when the fix changes behavior an app could observe.

## Before 1.0 (now)

Desen is in alpha (`0.x`, pre-release tags like `0.1.0-alpha.1`). Until 1.0:

- **Breaking changes may land in a minor bump** (`0.1` → `0.2`), never in a
  patch bump. Every one is listed under *Breaking* in the changelog with a
  before/after table (the migration note); no deprecation period is needed.
- `-alpha.N` and `-beta.N` pre-releases may break anything between them;
  they exist for early adopters who read the changelog.
- `fix_data.yaml` (`dart fix` migrations) is optional before 1.0.

## From 1.0 on

- **Breaking changes only in a major release.**
- **Deprecate first.** A public API is marked `@Deprecated('Use X instead.
  Deprecated in 1.N.')` in a minor release and removed no earlier than the
  next major, with at least one minor release in between. The deprecated
  API keeps working until it is removed.
- Every rename or removal ships a `lib/fix_data.yaml` entry where `dart fix`
  can express it, and a changelog migration note where it cannot.
- Deprecations are listed under *Deprecated* in the changelog of the release
  that introduces them, and again under *Breaking* when they are removed.

## Fonts

The font files (Schibsted Grotesk, Geist Mono) are part of the package, in
`fonts/`, and are versioned with it. Updating a font file changes glyphs or
metrics and moves text in goldens, so it is listed under *Changed*.
Removing or renaming a family or a weight is a breaking change: apps may
name them in their own text styles.

## Flutter versions

Desen supports the Flutter stable named in `pubspec.yaml` (`flutter:`) and
later stables. CI runs on a pinned stable; a beta job warns early about the
next one. A new Flutter stable that breaks Desen gets a patch release.
