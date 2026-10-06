# desen_ui_fonts

The typefaces of [Desen UI](../README.md): Schibsted Grotesk for text and numbers, Geist Mono for code.

Optional. Add it for Desen's default look:

```yaml
dependencies:
  desen_ui: ...
  desen_ui_fonts: ...
```

Without it, Desen falls back to the platform font, or to your own families via `DsTypography(family: …, monoFamily: …)` (families declared in your app need no `package`).

Licenses: both fonts are under the SIL Open Font License 1.1 (`fonts/OFL-*.txt`).
