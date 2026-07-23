# 设置页模式

> 参考实现：开听 `lib/presentation/screens/settings_screen.dart` + `widgets/settings_components.dart`；开卷 `lib/presentation/screens/settings_screen.dart` + `widgets/settings_components.dart`。两端均已落地，命名分别为 `SoundSettings*` / `AppSettings*`。

## 布局

- 内容居中限宽 920；页边距 16/32（窄/宽）；
- 桌面页头：`SettingsPageHeader`（26/28 w800 负字距标题 + 可选副题 + 可选返回钮）；移动端页头由外壳提供，不重复；
- 分区：小节标签（12.5 w600 secondary，左内缩 4）+ 分组卡片，区间距 28（移动端可收窄到 22）；
- **单页滚动，不用分区 tabs / 滚动联动**——分组卡片本身已提供足够的扫读结构，tabs 是噪音。

## 分组卡片（SettingsGroup）

设置项收进圆角分组卡，不漂浮在画布上：

| 部位 | 值 |
|---|---|
| 圆角 | 14（card 档） |
| 填充 | surfaceContainerLow @72% |
| 边框 | hairline |
| 行间分隔 | hairline，indent / endIndent 14，自动插入 |

**选中态用行内 check / accent 文字，禁止整行填充块。**

## 行（三类呈现）

1. **导航行**：标题 13.5 w600 primary + 副题 11.5 secondary 堆叠（双端统一，不用桌面端单行富文本混排）；行尾 value 12.5 secondary w500 + chevron 19 secondary；padding 14h/8v；行高 ≥64（桌面）/ ≥58（移动）；
2. **开关行**：同上行结构，Switch trailing；
3. **选择行**：行内 check，或下述预览卡 / 色板直接展示；
4. 危险操作（清库等）放分区末尾，destructive 样式。

## 外观区：选择器直接展示

皮肤、主题色、播放器样式这类「看一眼就想点」的选择器**在分组卡内直接展示**，不藏在折叠行后面。卡内用子块标签（`SettingsBlockLabel`，12.5 w600 secondary，14/12/14/2 内边距）分隔各选择器，子块间走分组卡的分隔线。

### 皮肤预览卡（SkinCard）

```
┌────────────┐   124×80，r12，hairline 描边
│ 画布色      │   内部：0.74×0.64 的 elevated 小卡（r7 + glass.border），
│  ┌──────┐  │   卡内：accent 短条(13×4) + 两条假文字行(0.78/0.52 宽, 3.5 高,
│  │ ▬    │  │   primaryText@0.22 / secondaryText@0.32)
│  │ ───  │  │
│  │ ──   │  │   选中：accent 2px 描边 + 下方标签 accent w700
│  └──────┘  │   未选：hairline 描边 + 标签 secondary w500（12px）
└────────────┘   不放 check 角标——描边 + 标签已足够
   皮肤名
```

- 「跟随系统」卡 = 默认/深夜双拼（左右各半）；
- 卡片横排 Wrap，间距 14；换行自然；
- 预览卡里只用 DecoratedBox/Container，不嵌 Icon 与图片，保证它是纯 token 的函数。

### 主题色板（AccentSwatch）

- 28px 圆点横排（含「自定义」彩虹渐变点），间距 12；
- 选中：1.5px primary 描边 + 中心 8px onAccent 圆点；未选：无描边（自定义点带 hairline）；
- 不用 check 图标、不加投影。

## 信息区（关于）

- 品牌名 + 一句话定位置于分组上方（15 w700 / 12.5 secondary，左右内缩 14）；
- 行高 ≥46，padding 14h/6v；标签列 52 宽 secondary 13px，值列 primary 13 w500（可选中复制）；
- 行尾动作（复制等）：15–16px muted 图标钮，右对齐。

## 规则

1. 移动端长列表选择（播放模式、睡眠定时）用底部弹层承载（`CompactSettingsSheet`：20/18/20/16 内边距、选项行高 ≥48、选中行尾 check）；桌面端行内展开即可；
2. 桌面端行内展开的选择器（chips 条等）直接放进分组卡，内边距 14，不加额外面板边框——分隔交给分组卡；
3. 不出现「另一产品」的入口。
