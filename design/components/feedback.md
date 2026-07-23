# 反馈（SnackBar / Tooltip / 空态 / 加载 / 滚动条 / 进度指示）

- **参考实现**：kaiting `sound_components.dart → SoundEmptyState`、`sound_theme.dart`；kaijuan `app_components.dart → AppEmptyState`、`app_overlays.dart → showAppSnackBar / AppTooltip`。

## SnackBar（轻提示）

| 部位 | 值 |
|---|---|
| 形态 | floating，overlay 面 + border，r12（menu 档） |
| 文字 | bodyMedium primary；action accent |
| 时长 | 1.4s（轻提示） |
| 桌面呈现 | 居中窄条（宽 220，窗口 <420 时收缩），距底 36 |
| 移动呈现 | 左右 16、距底 18 |

规则：新提示顶掉旧提示（clearSnackBars）；不用 action 时保持纯文本一行；下滑关闭。

## Tooltip

- overlay 面 + border，r8，10h/7v 内边距，bodySmall 染 primary；
- 延迟 450ms、展示 3s；message 为空时不挂 tooltip；
- 中文文案，仅桌面指向设备依赖它。

## 空态 / 加载 / 错误（EmptyState）

```
[30px muted 图标（68% 透明） 或 24px 2px 加载圈]
14
[16px w600 标题（primary 88%）]
6
[12px 说明（muted 76%，行高 1.45）]
```

- 最大内容宽 420，居中，页面底部留白按壳规范；
- 加载指示统一：24px、strokeWidth 2（accent 由 progressIndicatorTheme 供给），禁止自定义颜色；
- 空态图标用描线款（weight 300）。

## 滚动条

5px 胶囊；thumb secondary 30%（hover 55%）；轨道透明；桌面常驻可显，触屏淡入淡出。

## 行内进度（LinearProgressIndicator）

accent 色、轨道透明；仅用于确定/不确定进度，不用作分隔线。

## 验收锚点

- snackbar overlay 面 r12 非纯黑条；
- 加载圈 24px/2px 无硬编码色；
- 空态 maxWidth 420、图标 30px muted。
