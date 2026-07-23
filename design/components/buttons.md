# 按钮族（Button / IconButton / ToolbarButton / FAB）

- **用途**：主操作、次操作、工具触发、图标操作。
- **参考实现**：kaiting `lib/core/sound_theme.dart`（按钮子主题）、`sound_components.dart → SoundToolbarButton`；kaijuan `lib/core/theme/app_theme.dart`、`app_overlays.dart → AppIconButton`。

## 解剖与 Metrics

| 按钮 | 形状 | 最小尺寸 | 内边距 | 文字 | 图标 |
|---|---|---|---|---|---|
| Filled / Elevated / Outlined / Text | 胶囊（pill） | 36×36 | 14h/7v（TextButton 12h/8v） | labelMedium w700 | 17 |
| IconButton | 正圆 | 40×40 | — | — | 20 |
| ToolbarButton | 胶囊 | 高 32 | 8–10h | 12 w600 secondary | 16 secondary |
| FAB | 正圆 | 默认 | — | — | accent |

## Token 映射与状态

**Filled/Elevated（安静胶囊——不是实心大色块）**：

| 状态 | 背景 | 前景 |
|---|---|---|
| default | 前景 4.5% | accent |
| hovered / focused | 前景 7.5% | accent |
| pressed | 前景 11% | accent |
| disabled | 前景 2.2% | secondary 38% |

**Outlined/Text（更安静）**：default 前景 2.5%（Text 透明）、hover 5.5%、pressed 8.5%；前景 accent。

**IconButton**：背景透明；hover 前景 6.5%、pressed 10%；前景 primary（选中态 accent）；focus 2px accent 描边。

**FAB**：背景前景 4.5%，图标 accent，无 elevation。

**Destructive**：背景 error 8%（hover 12% / pressed 16% / disabled 2.5%），文字 error。

## 交互

- 状态过渡 160ms easeOutCubic；NoSplash。
- 对话框按钮区：OverflowBar 右对齐，间距 10；主按钮在右。
- 同一区域最多一个主强调按钮。

## 禁止事项

- 禁止实心 accent 大色块按钮（除内容层特殊场景）；
- 禁止自定义圆角（一律 pill）；
- 禁止阴影。

## 验收锚点

- 按钮胶囊形、最小 36px、iconSize 17；
- IconButton 40px 正圆、图标 20；
- filled 默认背景 = 前景色 @4.5%。
