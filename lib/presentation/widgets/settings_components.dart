import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';

abstract final class SoundSettingsMetrics {
  static const maxContentWidth = 920.0;
  static const sectionGap = 28.0;
  static const rowMinHeight = 64.0;
  static const compactRowMinHeight = 58.0;
}

extension SoundSettingsContext on BuildContext {
  Color get settingsPrimary => soundPrimaryText;
  Color get settingsSecondary => soundSecondaryText;
  Color get settingsMuted => soundMutedText;
  Color get settingsHairline =>
      soundDivider.withValues(alpha: soundDivider.a * 0.72);
  Color get settingsInlineSurface =>
      soundColors.surfaceContainerLow.withValues(alpha: 0.72);
}

class SoundSettingsContent extends StatelessWidget {
  const SoundSettingsContent({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = SoundSettingsMetrics.maxContentWidth,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SoundSettingsScrollView extends StatelessWidget {
  const SoundSettingsScrollView({
    required this.children,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SoundSettingsContent(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class SoundSettingsPageHeader extends StatelessWidget {
  const SoundSettingsPageHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.backButtonKey,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Key? backButtonKey;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null) ...[
              IconButton(
                key: backButtonKey,
                onPressed: onBack,
                tooltip: '返回设置',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.settingsPrimary,
                  fontSize: context.soundPageTitleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.55,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...actions,
          ],
        ),
        if (subtitle case final value?) ...[
          SizedBox(height: onBack == null ? 6 : 4),
          Padding(
            padding: EdgeInsets.only(left: onBack == null ? 0 : 56),
            child: Text(
              value,
              style: TextStyle(
                color: context.settingsSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SoundSettingsInlinePanel extends StatelessWidget {
  const SoundSettingsInlinePanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.settingsInlineSurface,
        border: Border.symmetric(
          horizontal: BorderSide(color: context.settingsHairline),
        ),
      ),
      child: child,
    );
  }
}
