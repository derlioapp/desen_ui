import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/spring_value.dart';
import '../../foundation/platform.dart';
import '../../overlay/modal_route.dart';
import '../../painting/decoration.dart';
import '../../painting/shape.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'text_magnifier_style.dart';

/// The loupe over the text under the finger, shown on iOS and Android while
/// a selection handle is dragged or a long press selects, so the finger
/// does not hide the caret or the edge of the selection.
///
/// Desen's text fields show it on their own ([configuration]); nothing
/// needs to be set up. It floats [DsTextMagnifierStyle.lift] above the
/// line, follows the finger along it without running past either end of
/// the line, and keeps to the window. A move to another line glides; with
/// reduced motion it jumps. It grows in as it appears and shrinks away as
/// it goes, fading both ways; with reduced motion it only fades.
///
/// Style it with a [DsTextMagnifierTheme]:
///
/// ```dart
/// DsTextMagnifierTheme(
///   data: const DsTextMagnifierThemeData(
///     style: DsTextMagnifierStyle(magnification: 1.5),
///   ),
///   child: form,
/// )
/// ```
class DsTextMagnifier extends StatefulWidget {
  /// Creates a loupe that follows [magnifierInfo].
  const DsTextMagnifier({
    super.key,
    required this.magnifierInfo,
    this.controller,
    this.style,
  });

  /// Where the finger, the caret, the line and the field are, in the root
  /// overlay's coordinates. The framework updates it as the gesture moves.
  final ValueListenable<MagnifierInfo> magnifierInfo;

  /// The controller that shows and hides the loupe, as passed to a
  /// [TextMagnifierConfiguration.magnifierBuilder]. With it, hiding plays a
  /// short exit before the loupe leaves the overlay; without it, the loupe
  /// goes at once.
  final MagnifierController? controller;

  /// Style laid over the theme and defaults.
  final DsTextMagnifierStyle? style;

  /// The magnifier setting of Desen's text fields: this loupe on iOS and
  /// Android, none on desktop. Pass it as `magnifierConfiguration` to an
  /// `EditableText` of your own for the same behavior.
  ///
  /// The loupe sits above the selection handles, so the handle under the
  /// finger shows enlarged inside it, as on iOS.
  static const TextMagnifierConfiguration configuration =
      TextMagnifierConfiguration(magnifierBuilder: _build);

  static Widget? _build(
    BuildContext context,
    MagnifierController controller,
    ValueNotifier<MagnifierInfo> info,
  ) {
    if (!isTouchPlatform(defaultTargetPlatform)) return null;
    // The loupe lives in the root overlay; carry over the field's theme,
    // direction and component themes.
    final captured = DsCapturedThemes.capture(
      from: context,
      to: Overlay.maybeOf(context, rootOverlay: true)?.context,
    );
    return captured.wrap(
      DsTextMagnifier(magnifierInfo: info, controller: controller),
    );
  }

  /// Desen's default loupe style under [theme].
  static DsTextMagnifierStyle defaultStyle(DsThemeData theme) {
    const height = 40.0;
    return DsTextMagnifierStyle(
      width: 80,
      height: height,
      magnification: 1.25,
      lift: 22,
      // A small floating control: rounded by its height, a capsule in the
      // pill corner style.
      borderRadius: BorderRadius.circular(theme.radii.control(height)),
      shadows: theme.shadows.overlay,
    );
  }

  @override
  State<DsTextMagnifier> createState() => _DsTextMagnifierState();
}

class _DsTextMagnifierState extends State<DsTextMagnifier>
    with SingleTickerProviderStateMixin {
  /// False for the first frame, so the loupe fades in.
  bool _shown = false;

  /// 1 while shown. The controller runs it back to 0 when it hides the
  /// loupe and removes the loupe once it gets there.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    value: 1,
    // Reduced motion keeps fades: the platform's disable-animations
    // setting must not speed this one up to nothing.
    animationBehavior: AnimationBehavior.preserve,
  )..addListener(() => setState(() {}));

  @override
  void initState() {
    super.initState();
    widget.magnifierInfo.addListener(_onInfo);
    widget.controller?.animationController = _exit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void didUpdateWidget(DsTextMagnifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magnifierInfo != widget.magnifierInfo) {
      oldWidget.magnifierInfo.removeListener(_onInfo);
      widget.magnifierInfo.addListener(_onInfo);
    }
    if (oldWidget.controller != widget.controller) {
      _release(oldWidget.controller);
      widget.controller?.animationController = _exit;
    }
  }

  @override
  void dispose() {
    widget.magnifierInfo.removeListener(_onInfo);
    _release(widget.controller);
    _exit.dispose();
    super.dispose();
  }

  /// Hands [controller] back without an exit, unless another loupe has
  /// taken it since.
  void _release(MagnifierController? controller) {
    if (controller?.animationController == _exit) {
      controller!.animationController = null;
    }
  }

  void _onInfo() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final s = DsTextMagnifierStyle.resolveLayers([
      DsTextMagnifier.defaultStyle(t),
      DsTextMagnifierTheme.of(context).style,
      widget.style,
    ], const {});
    final size = Size(s.width!, s.height!);
    final scale = s.magnification!;
    final lift = s.lift!;
    final radius = s.borderRadius ?? BorderRadius.zero;
    final info = widget.magnifierInfo.value;
    final screen = Offset.zero & MediaQuery.sizeOf(context);

    // Centered on the finger, its bottom [lift] above the middle of the
    // line, never past either end of the line; then kept on screen.
    final line = info.currentLineBoundaries;
    final x = clampDouble(info.globalGesturePosition.dx, line.left, line.right);
    final wanted = Rect.fromLTWH(
      x - size.width / 2,
      info.caretRect.center.dy - lift - size.height,
      size.width,
      size.height,
    );
    final placed = MagnifierController.shiftWithinBounds(
      bounds: screen,
      rect: wanted,
    );

    // What the loupe enlarges: the line under it, but never past the
    // field's sides (the middle of a field too narrow to fill it); when the
    // loupe was pushed down by the window's top, still the line.
    final field = info.fieldBounds;
    final reach = size.width / 2 / scale;
    final focusX = field.width < reach * 2
        ? field.center.dx
        : clampDouble(
            placed.center.dx,
            field.left + reach,
            field.right - reach,
          );
    final focus = Offset(
      focusX - placed.center.dx,
      wanted.top - placed.top + lift + size.height / 2,
    );

    final loupe = SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DsShapeClip(
            borderRadius: radius,
            child: RawMagnifier(
              size: size,
              magnificationScale: scale,
              focalPointOffset: focus,
            ),
          ),
          // Edge and elevation over the enlarged text: outer shadows fall
          // outside the loupe, where they cannot be enlarged with it.
          Positioned.fill(
            child: DecoratedBox(
              decoration: DsBoxDecoration(
                borderRadius: radius,
                shadows: s.shadows ?? const [],
              ),
            ),
          ),
        ],
      ),
    );

    final motion = t.motion;
    _exit.duration = motion.toneDuration;
    // The exit: a fade, and on the way out a shrink back towards the line
    // unless motion is reduced.
    final exit = motion.toneCurve.transform(_exit.value);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          children: [
            // Only a move to another line changes the top: it glides there.
            DsSpringValue(
              value: placed.top,
              spring: motion.moveSpringOrNull,
              builder: (context, top, child) =>
                  Positioned(left: placed.left, top: top, child: child!),
              child: DsSpringValue(
                value: _shown ? 1 : 0,
                spring: motion.toneSpring,
                builder: (context, v, child) =>
                    Opacity(opacity: clampDouble(v, 0, 1) * exit, child: child),
                // Grows out of the line like other floating layers; with
                // reduced motion it only fades.
                child: DsSpringValue(
                  value: _shown ? 1 : 0,
                  spring: motion.moveSpringOrNull,
                  builder: (context, v, child) => Transform.scale(
                    scale:
                        lerpDouble(motion.overlayScale, 1, v)! *
                        (motion.reduced
                            ? 1
                            : lerpDouble(motion.overlayScale, 1, exit)!),
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                  child: loupe,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
