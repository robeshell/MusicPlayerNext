import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sound_theme.dart';

/// Shared translucent surface used by the application shell and overlays.
///
/// Backdrop blur is intentionally optional: floating surfaces use it, while
/// repeated rows and cards can share the same visual language without paying
/// the cost of dozens of independent blur filters.
class SoundGlassSurface extends StatelessWidget {
  const SoundGlassSurface({
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(SoundRadii.sheet),
    ),
    this.strong = false,
    this.blur = true,
    this.showShadow = true,
    this.shadowOffset = const Offset(0, 10),
    this.shadowBlur,
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final bool strong;
  final bool blur;
  final bool showShadow;
  final Offset shadowOffset;
  final double? shadowBlur;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final glass = context.soundGlass;
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? (strong ? glass.strongSurface : glass.surface),
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? glass.border),
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: strong ? glass.strongBlur : glass.blur,
                sigmaY: strong ? glass.strongBlur : glass.blur,
              ),
              child: surface,
            )
          : surface,
    );
    if (!showShadow) return clipped;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: glass.shadow,
            blurRadius: shadowBlur ?? (strong ? 34 : 24),
            offset: shadowOffset,
          ),
        ],
      ),
      child: clipped,
    );
  }
}

bool get usesDesktopTrackActivation =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Gives browseable song rows platform-appropriate activation behavior.
///
/// Desktop users select a row with one click and play it with a double-click
/// or Enter. Touch platforms keep the expected single-tap-to-play behavior.
class SoundTrackActivation extends StatefulWidget {
  const SoundTrackActivation({
    required this.onActivate,
    required this.child,
    this.semanticLabel,
    this.showFocusOutline = true,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(SoundRadii.control),
    ),
    super.key,
  });

  final VoidCallback onActivate;
  final Widget child;
  final String? semanticLabel;
  final bool showFocusOutline;
  final BorderRadius borderRadius;

  @override
  State<SoundTrackActivation> createState() => _SoundTrackActivationState();
}

class _SoundTrackActivationState extends State<SoundTrackActivation> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: widget.semanticLabel);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      widget.onActivate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = usesDesktopTrackActivation;
    final theme = Theme.of(context);
    final semanticLabel = widget.semanticLabel == null
        ? null
        : desktop
        ? '${widget.semanticLabel}，双击播放'
        : '${widget.semanticLabel}，轻点播放';
    return Semantics(
      button: true,
      selected: desktop && _focused,
      label: semanticLabel,
      onTap: widget.onActivate,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: desktop,
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
        },
        onKeyEvent: _handleKeyEvent,
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: desktop ? _focusNode.requestFocus : widget.onActivate,
            onDoubleTap: desktop
                ? () {
                    _focusNode.requestFocus();
                    widget.onActivate();
                  }
                : null,
            borderRadius: widget.borderRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(borderRadius: widget.borderRadius),
              foregroundDecoration: BoxDecoration(
                color: desktop && _focused
                    ? SoundColors.accent.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: widget.borderRadius,
                border: desktop && _focused && widget.showFocusOutline
                    ? Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.46,
                        ),
                      )
                    : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class SoundDialog extends StatelessWidget {
  const SoundDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    this.maxWidth = 520,
    this.titlePadding = const EdgeInsets.fromLTRB(24, 22, 20, 16),
    this.contentPadding = const EdgeInsets.fromLTRB(24, 0, 24, 20),
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 14, 20, 20),
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsetsGeometry titlePadding;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogTheme = DialogTheme.of(context);
    final viewport = MediaQuery.sizeOf(context);
    const horizontalInset = 20.0;
    const verticalInset = 24.0;

    // Keep the route child responsible for its own bounds. Wrapping an
    // AlertDialog with a BackdropFilter makes the wrapper inherit the route's
    // loose full-height constraints, which can stretch otherwise short dialog
    // content (tables are especially visible). The surface now shrink-wraps
    // short content and gives only the content area the remaining height.
    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: viewport.height > verticalInset * 2
              ? viewport.height - verticalInset * 2
              : 0,
        ),
        child: SizedBox(
          key: const ValueKey('sound-dialog'),
          width: maxWidth,
          child: SoundGlassSurface(
            strong: true,
            borderRadius: BorderRadius.circular(SoundRadii.dialog),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: titlePadding,
                    child: DefaultTextStyle(
                      style:
                          dialogTheme.titleTextStyle ??
                          theme.textTheme.headlineSmall!,
                      child: title,
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      key: const ValueKey('sound-dialog-content-scroll'),
                      padding: contentPadding,
                      child: DefaultTextStyle(
                        style:
                            dialogTheme.contentTextStyle ??
                            theme.textTheme.bodyMedium!,
                        child: KeyedSubtree(
                          key: const ValueKey('sound-dialog-content'),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: actionsPadding,
                      child: OverflowBar(
                        alignment: MainAxisAlignment.end,
                        overflowAlignment: OverflowBarAlignment.end,
                        spacing: 10,
                        overflowSpacing: 10,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showSoundBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showHandle = true,
  double maxWidth = 760,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: dark ? 0.62 : 0.38),
    elevation: 0,
    constraints: BoxConstraints(maxWidth: maxWidth),
    builder: (sheetContext) =>
        SoundBottomSheet(showHandle: showHandle, child: builder(sheetContext)),
  );
}

class SoundBottomSheet extends StatelessWidget {
  const SoundBottomSheet({
    required this.child,
    this.showHandle = true,
    super.key,
  });

  final Widget child;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoundGlassSurface(
      strong: true,
      shadowOffset: const Offset(0, -8),
      shadowBlur: 28,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(SoundRadii.sheet),
      ),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(SoundRadii.sheet),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: showHandle ? 14 : 0),
                child: child,
              ),
              if (showHandle)
                Positioned(
                  top: 7,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.38,
                        ),
                        borderRadius: BorderRadius.circular(SoundRadii.pill),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoundNavigationItem {
  const SoundNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class SoundNavigationBar extends StatelessWidget {
  const SoundNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SoundNavigationItem> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoundGlassSurface(
      strong: true,
      shadowOffset: const Offset(0, -6),
      shadowBlur: 18,
      borderRadius: BorderRadius.zero,
      borderColor: theme.colorScheme.outlineVariant,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 7, 10, 6),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _SoundNavigationButton(
                    item: destinations[index],
                    selected: index == selectedIndex,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundNavigationButton extends StatelessWidget {
  const _SoundNavigationButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SoundNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? SoundColors.accent
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SoundRadii.control),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected
                    ? SoundColors.accent.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(SoundRadii.control),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 21,
                    color: foreground,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 10.5,
                      height: 1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
