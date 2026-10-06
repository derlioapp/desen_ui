import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../foundation/color_utils.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../button/button_theme.dart';
import '../field/field.dart';
import '../progress/progress.dart';
import '../progress/progress_bar_style.dart';
import '../selection/error_edge.dart';
import 'dashed_border.dart';
import 'file_item_style.dart';
import 'file_size.dart';
import 'file_upload_style.dart';

/// A file drop zone with the files being uploaded below it (concept 34).
///
/// ```dart
/// DsField(
///   label: const Text('Ekler'),
///   errorText: tooBig ? 'Dosya 10 MB\'tan büyük.' : null,
///   child: DsFileUpload(
///     onBrowse: pickFiles,
///     dragging: isDragging,
///     description: const Text('PDF, PNG · en fazla 10 MB'),
///     files: [
///       for (final f in uploads)
///         DsFileItem(
///           name: f.name,
///           size: f.bytes,
///           status: f.status,
///           progress: f.progress,
///           onCancel: () => cancel(f),
///           onRemove: () => remove(f),
///           onRetry: () => retry(f),
///         ),
///     ],
///   ),
/// )
/// ```
///
/// **Presentational.** Desen does not pick or receive files itself, so the
/// library needs no plugin. The app opens its picker in [onBrowse] (e.g.
/// `file_picker`, or an `<input type=file>` on the web) and reports a
/// drag over the zone with [dragging], from whatever receives drops on its
/// platforms:
///
/// - **Desktop and web, `desktop_drop`:** wrap the zone in its
///   `DropTarget`; set [dragging] in `onDragEntered` / `onDragExited` and
///   upload in `onDragDone`.
/// - **`super_drag_and_drop`:** a `DropRegion` around the zone; set
///   [dragging] in `onDropEnter` / `onDropLeave`, read the files in
///   `onPerformDrop`.
/// - **Web without a plugin:** listen to `dragenter`, `dragleave` and
///   `drop` on the page with `package:web` and hit-test the pointer
///   position against the zone's box.
///
/// Flutter 3.47's widgets layer has no drop target of its own, so there is
/// no built-in hook to switch on.
///
/// **Anatomy.** A dashed edge (concept "E", 1.5px) around an upload icon,
/// the prompt with the "browse" word as a link, and an optional
/// [description] (types, size limit). While [dragging], the edge takes the
/// accent and the zone a tint, and the prompt says to drop. [files]
/// (usually [DsFileItem]s) follow below, read as a list.
///
/// **Keyboard.** The zone is one Tab stop: Enter or Space browses, as a
/// click anywhere on it does. Each row's buttons are Tab stops of their
/// own.
///
/// **Field.** Inside a [DsField] the zone takes the field's error look (a
/// 2px error edge) and its label names it; the rows keep their own
/// nodes. [error] sets the error look when it stands alone.
///
/// **Disabled.** A null [onBrowse] disables the zone: no focus, no hover,
/// the disabled fill and faint ink; the rows stay as they are.
///
/// Works without `DsScope`, in RTL and with large text.
class DsFileUpload extends StatefulWidget {
  /// Creates a drop zone.
  const DsFileUpload({
    super.key,
    required this.onBrowse,
    this.files = const [],
    this.dragging = false,
    this.error = false,
    this.title,
    this.description,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  });

  /// Opens the app's file picker. Null disables the zone.
  final VoidCallback? onBrowse;

  /// The files below the zone, usually [DsFileItem]s.
  final List<Widget> files;

  /// Files are being dragged over the zone: the accent edge, a tint and
  /// the "drop" prompt. The app sets it from its drop target.
  final bool dragging;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Replaces the localized prompt ("Drop files here or browse").
  final Widget? title;

  /// A line under the prompt, e.g. accepted types and the size limit.
  final Widget? description;

  /// Replaces the upload icon.
  final Widget? icon;

  /// Focus node of the zone; one is created when null.
  final FocusNode? focusNode;

  /// Whether the zone takes focus when first built.
  final bool autofocus;

  /// Replaces what screen readers hear for the zone (by default the field
  /// label, the prompt and the description).
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsFileUploadStyle? style;

  /// Desen's default style under [theme].
  static DsFileUploadStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    final type = theme.typography;
    // Proportional figures: the description is prose ("PDF, PNG · up to 10 MB").
    // Tabular figures in the text family also make the comma and period
    // digit-wide, which tears "PDF, PNG" apart (denetim-2, decision 1).
    // The scale's smallest size, the overline's (11, touch 12).
    final description = type.caption.copyWith(fontSize: type.overline.fontSize);
    return DsFileUploadStyle(
      width: 360,
      height: 104,
      padding: const EdgeInsets.all(DsSpace.s16),
      background: k.surface,
      // A form boundary (3:1), as on the dashed card: the zone is a target.
      borderColor: k.borderField,
      borderWidth: 1.5,
      dashLength: 6,
      dashGap: 4,
      borderRadius: BorderRadius.circular(theme.radii.card),
      iconColor: k.textSubtle,
      iconSize: 20,
      titleStyle: type.body.copyWith(color: k.text),
      actionStyle: TextStyle(color: k.link, fontWeight: FontWeight.w600),
      descriptionStyle: description.copyWith(color: k.textSubtle),
      gap: DsSpace.s4,
      listGap: DsSpace.s8,
      focusShadows: theme.focusShadows,
      // The fills would pull the edge under 3:1; it steps up with them.
      hovered: DsFileUploadStyle(
        background: Color.alphaBlend(k.hover, k.surface),
        borderColor: k.textMuted,
      ),
      pressed: DsFileUploadStyle(
        background: Color.alphaBlend(k.press, k.surface),
        borderColor: k.textMuted,
      ),
      // Files over the zone: the accent edge and a tint.
      selected: DsFileUploadStyle(
        background: Color.alphaBlend(k.accentTint, k.surface),
        borderColor: k.indicator,
        iconColor: k.accentText,
      ),
      // Thicker, so the error is not told by hue alone (K-67).
      error: DsFileUploadStyle(borderColor: dsErrorEdge(theme), borderWidth: 2),
      // Keeps its shape (K-66): the disabled fill, a faint edge.
      disabled: DsFileUploadStyle(
        background: k.disabled,
        borderColor: k.border,
        iconColor: k.onDisabled,
        titleStyle: TextStyle(color: k.onDisabled),
        actionStyle: TextStyle(color: k.onDisabled),
        descriptionStyle: TextStyle(color: k.onDisabled),
      ),
    );
  }

  @override
  State<DsFileUpload> createState() => _DsFileUploadState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty('enabled', value: onBrowse != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('dragging', value: dragging, ifTrue: 'dragging'))
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(IntProperty('files', files.length));
  }
}

/// Marks rows that sit in a [DsFileUpload]'s list: they are list items.
class _FileList extends InheritedWidget {
  const _FileList({required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_FileList>() != null;

  @override
  bool updateShouldNotify(_FileList oldWidget) => false;
}

/// The plain text of [widget] when it is a [Text].
String? _plain(Widget? widget) => switch (widget) {
  Text(:final data?) => data,
  Text(:final textSpan?) => textSpan.toPlainText(),
  _ => null,
};

class _DsFileUploadState extends State<DsFileUpload> {
  Set<WidgetState>? _lastStates;
  DsFieldHooks? _hooks;

  @override
  void dispose() {
    _hooks?.separateNodes = false;
    super.dispose();
  }

  /// The rows keep their own semantics nodes inside a field.
  void _report(DsFieldHooks? hooks) {
    if (_hooks != hooks) {
      _hooks?.separateNodes = false;
      _hooks = hooks;
    }
    hooks?.separateNodes = true;
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final l10n = DsLocalizations.of(context);
    final field = DsFieldScope.maybeOf(context);
    _report(field?.hooks);
    final error = widget.error || (field?.hasError ?? false);
    final layers = [
      DsFileUpload.defaultStyle(t),
      DsFileUploadTheme.of(context).style,
      widget.style,
    ];
    final base = DsFileUploadStyle.resolveLayers(layers, const {});

    // The prompt, with the "browse" word as a link wherever the language
    // puts it.
    const mark = '\u0000';
    final parts = l10n.fileUploadPrompt(mark).split(mark);
    final promptText = l10n.fileUploadPrompt(l10n.fileUploadBrowse);
    final titleText = widget.dragging
        ? l10n.fileUploadDrop
        : widget.title == null
        ? promptText
        : _plain(widget.title);
    final label =
        widget.semanticLabel ??
        [?field?.labelText, ?titleText, ?_plain(widget.description)].join('\n');

    final zone = DsPressable(
      onPressed: widget.onBrowse,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      validationResult: error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsFileUploadStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, states, _) {
        final all = {
          ...states,
          if (widget.dragging) WidgetState.selected,
          if (error) WidgetState.error,
        };
        final s = DsFileUploadStyle.resolveLayers(layers, all);
        final animate = _lastStates != null && !setEquals(_lastStates, all);
        _lastStates = all;
        final duration = animate ? t.motion.toneDuration : Duration.zero;
        final radius = s.borderRadius ?? BorderRadius.zero;
        final titleStyle = s.titleStyle ?? const TextStyle();
        final Widget title = widget.dragging
            ? Text(l10n.fileUploadDrop)
            : widget.title ??
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: parts.first),
                        TextSpan(
                          text: l10n.fileUploadBrowse,
                          style: s.actionStyle,
                        ),
                        if (parts.length > 1) TextSpan(text: parts.last),
                      ],
                    ),
                  );
        return Semantics(
          // Merged into the zone's node: the field label, the prompt and
          // the description, read once (the visuals are excluded); the
          // field's message (its error or description) as the hint.
          label: label,
          hint: field?.messageText,
          isRequired: (field?.isRequired ?? false) ? true : null,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: duration,
              curve: t.motion.toneCurve,
              constraints: BoxConstraints(minHeight: s.height ?? 0),
              decoration: DsBoxDecoration(
                color: s.background,
                borderRadius: radius,
                shadows: [
                  if (states.contains(WidgetState.focused)) ...?s.focusShadows,
                ],
              ),
              child: TweenAnimationBuilder<Color?>(
                tween: DsColorTween(end: s.borderColor),
                duration: duration,
                curve: t.motion.toneCurve,
                builder: (context, color, child) => DsDashedBorder(
                  color: color ?? const Color(0x00000000),
                  width: s.borderWidth ?? 0,
                  dashLength: s.dashLength ?? 0,
                  dashGap: s.dashGap ?? 0,
                  borderRadius: radius,
                  child: child,
                ),
                child: Padding(
                  padding: s.padding ?? EdgeInsets.zero,
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: s.gap ?? 0,
                      children: [
                        IconTheme.merge(
                          data: IconThemeData(
                            color: s.iconColor,
                            size: s.iconSize,
                          ),
                          child:
                              widget.icon ??
                              DsIcon(
                                DsIcons.upload,
                                color: s.iconColor,
                                size: s.iconSize,
                              ),
                        ),
                        DefaultTextStyle.merge(
                          style: titleStyle,
                          textAlign: TextAlign.center,
                          child: title,
                        ),
                        if (widget.description case final description?)
                          DefaultTextStyle.merge(
                            style: s.descriptionStyle,
                            textAlign: TextAlign.center,
                            child: description,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final gap = base.listGap ?? 0;
    final list = Semantics(
      container: true,
      role: SemanticsRole.list,
      explicitChildNodes: true,
      child: _FileList(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: widget.files,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final column = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [zone, if (widget.files.isNotEmpty) list],
        );
        // In an unbounded width (a Row) it takes its default width.
        return constraints.hasBoundedWidth
            ? column
            : SizedBox(width: base.width, child: column);
      },
    );
  }
}

/// The most of a row's name line the size and progress text may take.
const _metaShare = 2 / 3;

/// Where a file's upload stands.
enum DsFileStatus {
  /// Being uploaded: a progress bar and a cancel button.
  uploading,

  /// Uploaded: a success icon and a remove button.
  done,

  /// Failed: the error edge, a message, retry and remove buttons.
  error,
}

/// One file of a [DsFileUpload] (concept 34): its name, size and upload
/// state.
///
/// - [DsFileStatus.uploading]: a file icon, the progress bar (the accent
///   `indicator`), how much is sent and the percentage; [onCancel] adds a
///   cancel button. A null [progress] shows an indeterminate bar.
/// - [DsFileStatus.done]: the success icon and the size; [onRemove] adds a
///   remove button.
/// - [DsFileStatus.error]: a 2px error edge, the error icon and [message]
///   (or the localized "Upload failed"); [onRetry] and [onRemove] add
///   buttons.
///
/// Sizes are formatted the local way ([dsFormatFileSize]: "2,4 MB" in
/// Turkish). Screen readers hear the file name with its state ("kapak.png
/// yüklendi, 840 KB"), the progress bar's value and the buttons, each
/// named with the file. When the state changes to done or failed it is
/// announced politely (a polite live region where the platform has no
/// announcements's rule).
class DsFileItem extends StatefulWidget {
  /// Creates a file row.
  const DsFileItem({
    super.key,
    required this.name,
    this.status = DsFileStatus.done,
    this.size,
    this.progress,
    this.message,
    this.icon,
    this.onCancel,
    this.onRemove,
    this.onRetry,
    this.style,
  });

  /// The file name.
  final String name;

  /// Where the upload stands.
  final DsFileStatus status;

  /// The file size in bytes, if known.
  final int? size;

  /// Upload progress, 0–1, while [DsFileStatus.uploading]; null for an
  /// indeterminate bar.
  final double? progress;

  /// Why the upload failed, shown in [DsFileStatus.error] in place of the
  /// localized "Upload failed".
  final String? message;

  /// Replaces the file icon shown while uploading.
  final Widget? icon;

  /// Stops the upload; adds a cancel button while uploading.
  final VoidCallback? onCancel;

  /// Removes the file; adds a remove button when done or failed.
  final VoidCallback? onRemove;

  /// Tries again; adds a retry button when failed.
  final VoidCallback? onRetry;

  /// Style laid over the theme and defaults.
  final DsFileItemStyle? style;

  /// Desen's default style under [theme].
  static DsFileItemStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    final type = theme.typography;
    // A status icon takes the vivid signal when that reads at 3:1 on the
    // row (it does on the surface), else the status text color (K-33).
    Color readable(Color signal, Color text) =>
        DsColorUtils.contrastRatio(signal, k.surface) >= 3 ? signal : text;
    return DsFileItemStyle(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s12,
        vertical: DsSpace.s8,
      ),
      background: k.surface,
      shadows: theme.shadows.surface,
      borderRadius: BorderRadius.circular(theme.radii.card),
      iconColor: k.textMuted,
      successColor: readable(k.success.signal, k.success.text),
      errorColor: readable(k.danger.signal, k.danger.text),
      iconSize: 20,
      nameStyle: type.label.copyWith(color: k.text),
      // Proportional figures, like the drop zone's description: the meta runs
      // inline, where a digit-wide comma would tear "2,4" apart. The
      // overline's size, as the description.
      metaStyle: type.caption.copyWith(
        fontSize: type.overline.fontSize,
        color: k.textSubtle,
      ),
      messageStyle: type.caption.copyWith(color: k.danger.text),
      progressHeight: 4,
      gap: DsSpace.s12,
      textGap: DsSpace.s4,
      iconButtonStyle: DsButtonStyle(
        height: 24,
        iconSize: 14,
        foreground: k.textSubtle,
        hovered: DsButtonStyle(foreground: k.text),
        pressed: DsButtonStyle(foreground: k.text),
      ),
      textButtonStyle: DsButtonStyle(
        height: 28,
        textStyle: type.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      // Thicker than the content edge, in the error ink (K-67); the icon
      // and the message say it too (R5).
      error: DsFileItemStyle(
        shadows: [DsShadow.innerRing(dsErrorEdge(theme), width: 2)],
      ),
    );
  }

  @override
  State<DsFileItem> createState() => _DsFileItemState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(EnumProperty('status', status))
      ..add(IntProperty('size', size, defaultValue: null))
      ..add(DoubleProperty('progress', progress, defaultValue: null))
      ..add(StringProperty('message', message, defaultValue: null));
  }
}

class _DsFileItemState extends State<DsFileItem> {
  @override
  void didUpdateWidget(DsFileItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        widget.status != oldWidget.status ||
        (widget.status == DsFileStatus.error &&
            widget.message != oldWidget.message);
    if (!changed ||
        widget.status == DsFileStatus.uploading ||
        !MediaQuery.supportsAnnounceOf(context)) {
      return;
    }
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        _statusText(DsLocalizations.of(context)),
        Directionality.of(context),
      ),
    );
  }

  /// The state in words: "kapak.png yüklendi", "rapor.xlsx yüklenemedi\n
  /// Desteklenmeyen dosya türü".
  String _statusText(DsLocalizations l10n) => switch (widget.status) {
    DsFileStatus.uploading => '${widget.name}\n${l10n.uploading}',
    DsFileStatus.done => l10n.uploaded(widget.name),
    DsFileStatus.error => [
      l10n.uploadFailed(widget.name),
      widget.message ?? l10n.uploadError,
    ].join('\n'),
  };

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final l10n = DsLocalizations.of(context);
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final status = widget.status;
    final s = DsFileItemStyle.resolveLayers(
      [
        DsFileItem.defaultStyle(t),
        DsFileItemTheme.of(context).style,
        widget.style,
      ],
      {if (status == DsFileStatus.error) WidgetState.error},
    );

    String size(int bytes) =>
        dsFormatFileSize(bytes, locale: locale, strings: l10n);
    final progress = widget.progress?.clamp(0.0, 1.0);
    final percent = progress == null
        ? null
        : l10n.percent((progress * 100).round());
    final meta = switch (status) {
      DsFileStatus.uploading => switch ((widget.size, percent)) {
        (final total?, final percent?) => [
          dsFormatFileProgress(
            (total * progress!).round(),
            total,
            locale: locale,
            strings: l10n,
          ),
          percent,
        ].join(' · '),
        (_, final percent?) => percent,
        _ => l10n.uploading,
      },
      DsFileStatus.done => widget.size == null ? null : size(widget.size!),
      DsFileStatus.error => null,
    };
    final message = status == DsFileStatus.error
        ? widget.message ?? l10n.uploadError
        : null;

    final icon = switch (status) {
      DsFileStatus.uploading =>
        widget.icon ?? DsIcon(DsIcons.fileText, color: s.iconColor),
      DsFileStatus.done => DsIcon(DsIcons.circleCheck, color: s.successColor),
      DsFileStatus.error => DsIcon(DsIcons.circleAlert, color: s.errorColor),
    };

    // What the row says, as one node: the name with its state, the size
    // or progress, the message.
    final description = [_statusText(l10n), ?meta].join('\n');
    final text = Semantics(
      container: true,
      label: description,
      // Without announcements (Android), state changes are read from a
      // polite live region instead (never both).
      liveRegion: !MediaQuery.supportsAnnounceOf(context),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: s.textGap ?? 0,
          children: [
            LayoutBuilder(
              builder: (context, box) => Row(
                spacing: s.gap ?? 0,
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: s.nameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Never wider than its share, so a narrow row with large
                  // text keeps room for the name.
                  if (meta != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: box.maxWidth * _metaShare,
                      ),
                      child: Text(
                        meta,
                        style: s.metaStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (message != null) Text(message, style: s.messageStyle),
          ],
        ),
      ),
    );

    Widget iconButton(DsIconData data, String label, VoidCallback onPressed) =>
        DsButton.icon(
          variant: DsButtonVariant.ghost,
          size: DsSize.xs,
          style: s.iconButtonStyle,
          semanticLabel: label,
          onPressed: onPressed,
          icon: DsIcon(data),
        );
    final actions = <Widget>[
      if (status == DsFileStatus.uploading && widget.onCancel != null)
        iconButton(DsIcons.x, l10n.cancelUpload(widget.name), widget.onCancel!),
      if (status == DsFileStatus.error && widget.onRetry != null)
        DsButton(
          variant: DsButtonVariant.ghost,
          size: DsSize.xs,
          style: s.textButtonStyle,
          // Named with the file, so a list of failed files does not read
          // "Retry, Retry"; the visible word stays in the name.
          semanticLabel: l10n.retryUpload(widget.name),
          onPressed: widget.onRetry,
          child: Text(l10n.retry),
        ),
      if (status != DsFileStatus.uploading && widget.onRemove != null)
        iconButton(DsIcons.trash, l10n.remove(widget.name), widget.onRemove!),
    ];

    final row = Container(
      padding: s.padding,
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
        shadows: s.shadows ?? const [],
      ),
      child: IconTheme.merge(
        data: IconThemeData(size: s.iconSize),
        child: Row(
          spacing: s.gap ?? 0,
          children: [
            ExcludeSemantics(child: icon),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: s.textGap ?? 0,
                children: [
                  text,
                  if (status == DsFileStatus.uploading)
                    DsProgressBar(
                      value: progress,
                      style: DsProgressBarStyle(height: s.progressHeight ?? 0),
                      semanticLabel: widget.name,
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      role: _FileList.of(context) ? SemanticsRole.listItem : null,
      explicitChildNodes: true,
      child: row,
    );
  }
}
