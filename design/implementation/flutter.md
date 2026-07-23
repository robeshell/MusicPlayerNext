# DSL → Flutter 实现指南（Runbook）

> 目标读者：负责把本规范落到某个 Flutter 产品的工程师或 AI。按顺序执行。
> 参考实现：kaiting `lib/core/sound_theme.dart` + `lib/presentation/widgets/sound_components.dart`；kaijuan `lib/core/theme/` + `lib/presentation/widgets/app_components.dart`（**结构更接近本规范，优先参考**）。

## 第 0 步：确定产品 L0

- 从 `tokens/accents.json` 取产品的强调色轴（新产品则新增）；
- 确定内容层扩展点（阅读主题 / 播放器皮肤 / 无）。

## 第 1 步：主题层文件（建议结构）

```
lib/core/theme/
  tokens.dart    # L1：spacing、radii、AccentPreset、accent 预设（译自 primitives.json + accents.json）
  glass.dart     # L2：GlassTheme、SkinEffects（ThemeExtension，译自 skins.json 的 glass/effects）
  skins.dart     # L2：SkinPreset、Skins（预设常量 + byId + system 解析）
  context.dart   # BuildContext 扩展：glass、effects、三档文字、divider、tint、chromeSurface、destructiveButtonStyle
  app_theme.dart # L3：Theme.forSkin(skin, accent) → ThemeData
```

要点：

1. **ThemeExtension 承载语义层**：`GlassTheme`（11 字段）、`SkinEffects`（8 字段），含 `copyWith` 与 `lerp`；
2. **强调色注入 ColorScheme**（推荐 kaijuan 模型）：`ColorScheme.fromSeed(seedColor: accent).copyWith(primary: accent, onPrimary: 亮度估算, surfaceTint: transparent, surfaceContainer* ← 坡道, outline/outlineVariant ← border/hairline)`。**不要**用开听的静态变量突变模型（`SoundColors.accent = …`）——那是历史包袱；
3. `ThemeData` 全局：`useMaterial3`、`applyElevationOverlayColor: false`、`splashFactory: NoSplash.splashFactory`、`highlightColor/splashColor: transparent`、fontFamily + fallback、`extensions: [glass, effects]`；
4. TextTheme 按 `foundations/typography.md` 覆写（headline/title w800 负字距、bodySmall 染 secondary）。

## 第 2 步：ThemeData 子主题清单（22 项，逐项勾）

appBar / dialog / bottomSheet / snackBar / navigationBar / （可选 navigationRail）/ card / popupMenu / menu / dropdownMenu / inputDecoration / filledButton / elevatedButton / outlinedButton / textButton / iconButton / FAB / listTile / checkbox / radio / switch / slider / chip / divider / tooltip / scrollbar / progressIndicator。

每项的数值从 `components/*.md` 与 `derivedAlphas` 查表，**不允许**现场发明。

## 第 3 步：组件 kit（按依赖序）

1. **GlassSurface 第一**——所有浮面的原语（可选 blur + border + shadow × shadowScale；blur≤0 跳过 BackdropFilter）；
2. ChoiceStrip / ListRow / CheckRow / ToolbarButton / EmptyState；
3. Dialog、BottomSheet（含 show 函数）；
4. MenuAction / MenuButton / showMenu（自适应）；
5. NavigationBar；
6. （设置页）SettingsGroup / PageHeader / SkinCard。

规则：kit 组件只读 `context` 扩展与 `colorScheme`，不出现字面色值。

## 第 4 步：持久化与外壳

- 外观偏好：持久化 `skinPreset`（'system' 或预设 id）+ `accentPreset`；跟随系统用 `theme/darkTheme + ThemeMode.system` 映射到两个皮肤实现；
- 外壳按 `patterns/app-shell.md` 实现窗口分级与双壳；
- 旧存储迁移要写单元测试（参照 kaijuan `test/theme_preferences_test.dart`）。

## 第 5 步：自检

跑 `implementation/acceptance-checklist.md`：先静态分析与数值锚点，再人工巡检。

## 命名

规范用中性名；产品实现加前缀（`Sound*` / `App*` / 新产品自定）。文件结构与 getter 命名保持与 kaijuan `theme/` 一致，便于跨产品移植 diff。
