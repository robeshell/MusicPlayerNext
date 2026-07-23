# 对话框（Dialog）

- **用途**：确认、文本输入、表单、详情。
- **参考实现**：kaiting `sound_components.dart → SoundDialog`；kaijuan `app_components.dart → AppDialog`、`app_overlays.dart → showAppConfirmDialog / showAppTextPrompt`。

## 解剖

```
┌─ GlassSurface(strong, r20, shadow 34×scale) ─────────┐
│ 标题区   padding 24,22,20,16  titleLarge w800        │
│ 内容区   padding 24,0,24,20   bodyMedium secondary   │
│          （独立滚动，收缩包裹）                         │
│ 按钮区   padding 20,14,20,20  OverflowBar 右对齐      │
└──────────────────────────────────────────────────────┘
```

## Metrics

| 部位 | 值 |
|---|---|
| 圆角 | 20（dialog 档） |
| maxWidth | 520（确认/提示类 400） |
| 视口内边距 | 20h / 24v |
| 按钮间距 | 10 |

## Token 映射

| 部位 | token |
|---|---|
| 表面 | glass.strongSurface + glass.border + glass.shadow |
| 标题 | textTheme.titleLarge |
| 内容 | textTheme.bodyMedium 染 secondary |
| barrier | black 38%（浅）/ 62%（深） |

## 状态与交互

- 标题单行省略；内容超高时**内容区**滚动（对话框整体不滚）。
- 确认流返回 bool；文本输入流返回 String?，输入框 autofocus，Enter 提交。
- destructive 确认按钮用 destructive 样式（error 8% 底）。

## 实现要点（踩坑记录）

**BackdropFilter 包裹会使对话框继承路由的松散全高约束**，把矮内容拉高（表格类内容尤其明显）。表面必须 shrink-wrap：约束 maxHeight = 视口 − 48，内容区 Flexible + 独立 SingleChildScrollView。

## 禁止事项

- 禁止 AlertDialog 默认灰面与 elevation；
- 禁止对话框内出现第二个 accent 主按钮。

## 验收锚点

- r20、maxWidth 520、barrier 38%/62%；
- 矮内容对话框高度 = 内容高度（不被撑满）。
