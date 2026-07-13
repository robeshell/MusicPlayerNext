import 'package:flutter/material.dart';

abstract final class SoundColors {
  static const accent = Color(0xFFFA243C);
  static const darkCanvas = Color(0xFF0D0D0F);
  static const darkSurface = Color(0xFF17171A);
  static const darkElevated = Color(0xFF202024);
  static const darkOverlay = Color(0xFF29292E);
  static const lightCanvas = Color(0xFFF5F3F0);
  static const lightSurface = Color(0xFFFCFBF9);
  static const lightElevated = Color(0xFFFFFFFF);
  static const lightOverlay = Color(0xFFF0EDEA);
  static const webDav = Color(0xFF5E8BFF);
  static const local = Color(0xFF55B889);
}

abstract final class SoundRadii {
  static const control = 12.0;
  static const menu = 14.0;
  static const sheet = 22.0;
  static const dialog = 24.0;
  static const pill = 999.0;
}

abstract final class SoundTheme {
  static const _animationDuration = Duration(milliseconds: 160);
  static const _fontFallback = <String>[
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final canvas = dark ? SoundColors.darkCanvas : SoundColors.lightCanvas;
    final surface = dark ? SoundColors.darkSurface : SoundColors.lightSurface;
    final elevated = dark
        ? SoundColors.darkElevated
        : SoundColors.lightElevated;
    final overlay = dark ? SoundColors.darkOverlay : SoundColors.lightOverlay;
    final foreground = dark ? const Color(0xFFF7F3F4) : const Color(0xFF191719);
    final secondary = dark ? Colors.white60 : Colors.black54;
    final border = dark
        ? Colors.white.withValues(alpha: 0.11)
        : Colors.black.withValues(alpha: 0.10);
    final subtle = dark
        ? Colors.white.withValues(alpha: 0.055)
        : Colors.black.withValues(alpha: 0.045);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: SoundColors.accent,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: SoundColors.accent,
          onPrimary: Colors.white,
          surface: surface,
          onSurface: foreground,
          onSurfaceVariant: secondary,
          outline: border,
          outlineVariant: border.withValues(alpha: 0.7),
          surfaceContainerLowest: canvas,
          surfaceContainerLow: surface,
          surfaceContainer: elevated,
          surfaceContainerHigh: overlay,
          surfaceContainerHighest: overlay,
          scrim: Colors.black,
        );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      fontFamily: '.SF Pro Text',
      fontFamilyFallback: _fontFallback,
    ).textTheme.apply(bodyColor: foreground, displayColor: foreground);
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.55,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: secondary),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SoundRadii.control),
    );
    final focusOverlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.focused)) {
        return SoundColors.accent.withValues(alpha: 0.16);
      }
      if (states.contains(WidgetState.pressed)) {
        return foreground.withValues(alpha: 0.10);
      }
      if (states.contains(WidgetState.hovered)) {
        return foreground.withValues(alpha: 0.065);
      }
      return Colors.transparent;
    });
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      return states.contains(WidgetState.focused)
          ? const BorderSide(color: SoundColors.accent, width: 2)
          : null;
    });
    final standardButtonStyle = ButtonStyle(
      animationDuration: _animationDuration,
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 17, vertical: 10),
      ),
      shape: WidgetStatePropertyAll(controlShape),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: focusOverlay,
      side: focusSide,
    );
    final outlinedSide = WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: SoundColors.accent, width: 2);
      }
      return BorderSide(color: border);
    });
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(SoundRadii.control),
      borderSide: BorderSide(color: border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      cardColor: surface,
      fontFamily: '.SF Pro Text',
      fontFamilyFallback: _fontFallback,
      textTheme: textTheme,
      focusColor: SoundColors.accent.withValues(alpha: 0.20),
      hoverColor: foreground.withValues(alpha: 0.055),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      dividerColor: border,
      disabledColor: secondary.withValues(alpha: 0.38),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: canvas,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.42 : 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoundRadii.dialog),
          side: BorderSide(color: border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: secondary),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: elevated,
        modalBackgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.42 : 0.16),
        dragHandleColor: secondary.withValues(alpha: 0.45),
        dragHandleSize: const Size(38, 4),
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SoundRadii.sheet),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 760),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: overlay,
        actionTextColor: SoundColors.accent,
        disabledActionTextColor: secondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: foreground),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoundRadii.menu),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SoundColors.accent.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoundRadii.control),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          return IconThemeData(
            size: 21,
            color: states.contains(WidgetState.selected)
                ? SoundColors.accent
                : secondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? foreground
                : secondary,
          );
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.42 : 0.16),
        position: PopupMenuPosition.under,
        menuPadding: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoundRadii.menu),
          side: BorderSide(color: border),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(elevated),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: dark ? 0.42 : 0.16),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SoundRadii.menu),
              side: BorderSide(color: border),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: subtle,
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder.copyWith(
            borderSide: const BorderSide(color: SoundColors.accent, width: 2),
          ),
        ),
        menuStyle: MenuStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(elevated),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SoundRadii.menu),
              side: BorderSide(color: border),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: subtle,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: SoundColors.accent, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: secondary, fontWeight: FontWeight.w600),
        floatingLabelStyle: const TextStyle(
          color: SoundColors.accent,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: secondary.withValues(alpha: 0.7)),
        prefixIconColor: secondary,
        suffixIconColor: secondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: standardButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return SoundColors.accent.withValues(alpha: 0.30);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE51E34);
            }
            return SoundColors.accent;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: standardButtonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(overlay),
          foregroundColor: WidgetStatePropertyAll(foreground),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: standardButtonStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(foreground),
          side: outlinedSide,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: standardButtonStyle.copyWith(
          foregroundColor: const WidgetStatePropertyAll(SoundColors.accent),
          minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: _animationDuration,
          minimumSize: const WidgetStatePropertyAll(Size.square(40)),
          iconSize: const WidgetStatePropertyAll(20),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return secondary.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) {
              return SoundColors.accent;
            }
            return foreground;
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return foreground.withValues(alpha: 0.10);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return foreground.withValues(alpha: 0.065);
            }
            return Colors.transparent;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(controlShape),
          side: focusSide,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: SoundColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoundRadii.menu),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: secondary,
        textColor: foreground,
        selectedColor: SoundColors.accent,
        selectedTileColor: SoundColors.accent.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: controlShape,
      ),
      checkboxTheme: CheckboxThemeData(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: border, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return SoundColors.accent;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: focusOverlay,
      ),
      radioTheme: RadioThemeData(
        visualDensity: VisualDensity.compact,
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? SoundColors.accent
              : secondary;
        }),
        overlayColor: focusOverlay,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : secondary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? SoundColors.accent
              : border;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: focusOverlay,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: SoundColors.accent,
        inactiveTrackColor: border,
        thumbColor: SoundColors.accent,
        overlayColor: SoundColors.accent.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        showValueIndicator: ShowValueIndicator.never,
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        backgroundColor: subtle,
        selectedColor: SoundColors.accent.withValues(alpha: 0.16),
        disabledColor: subtle.withValues(alpha: 0.5),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoundRadii.pill),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: foreground),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          color: overlay,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: foreground),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(5),
        radius: const Radius.circular(SoundRadii.pill),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return secondary.withValues(
            alpha: states.contains(WidgetState.hovered) ? 0.55 : 0.30,
          );
        }),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SoundColors.accent,
        linearTrackColor: Colors.transparent,
      ),
    );
  }
}
