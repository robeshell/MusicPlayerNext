import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';
import '../../domain/library_models.dart';

class SourceBadge extends StatelessWidget {
  const SourceBadge(this.source, {super.key});

  final SourceKind source;

  @override
  Widget build(BuildContext context) {
    final tint = source == SourceKind.local
        ? SoundColors.local
        : SoundColors.webDav;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.soundTint(0.045),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.soundDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(source.icon, size: 11, color: tint),
            const SizedBox(width: 4),
            Text(
              source.label,
              style: TextStyle(
                color: context.soundMutedText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
