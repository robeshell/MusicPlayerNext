# 设置页模式

> 参考实现：kaijuan `lib/presentation/screens/settings_screen.dart`、`widgets/settings_components.dart`（本规范采用的方案）；开听设置页待按本篇改造。

## 布局

- 内容居中限宽 920；页边距 16/32（窄/宽）；
- 页头：`AppSettingsPageHeader`（26/28 w800 负字距标题 + 可选副题 + 可选返回钮）；
- 分区：小节标签（12 w600 secondary，左右内缩 4）+ 内容，区间距 28。

## 分组卡片（SettingsGroup）

设置项收进圆角分组卡，不漂浮在画布上：

| 部位 | 值 |
|---|---|
| 圆角 | 14（card 档） |
| 填充 | surfaceContainerLow @72% |
| 边框 | hairline |
| 行间分隔 | hairline，indent 14 |

**选中态用行内 check / accent 文字，禁止整行填充块。**

## 外观区：皮肤预览卡（SkinCard）

皮肤选项用迷你预览而非文字行：

```
┌────────────┐   124×80，r12，hairline 描边
│ 画布色      │   内部：0.74×0.64 的 elevated 小卡（r7 + glass.border），
│  ┌──────┐  │   卡内：accent 短条(13×4) + 两条假文字行(0.78/0.52 宽, 3.5 高)
│  │ ▬    │  │
│  │ ───  │  │   选中：accent 2px 描边 + 下方标签 accent w700
│  │ ──   │  │   未选：hairline 描边 + 标签 secondary w500（12px）
│  └──────┘  │
└────────────┘
   皮肤名
```

- 「跟随系统」卡 = 默认/深夜双拼（左右各半）；
- 卡片横排 Wrap，间距 14；换行自然；
- 强调色区：色板圆点（28px，选中 1.5px primary 描边 + 中心白点）收进分组卡。

## 信息区（关于）

- 行高 ≥46，padding 14h/6v；标签列 52–56 宽 secondary 13px，值列 primary 13 w500（可选中复制）；
- 行尾动作（复制等）：15–16px muted 图标钮，右对齐；
- 品牌名 + 一句话定位置于分组上方（15 w700 / 12.5 secondary）。

## 规则

1. 设置项三类呈现：导航行（ListRow + chevron）、开关行（Switch trailing）、选择行（行内 check 或预览卡）；
2. 危险操作（清库等）放分区末尾，destructive 样式；
3. 不出现「另一产品」的入口。
