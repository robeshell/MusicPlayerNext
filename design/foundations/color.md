# 配色规范（主视觉）

> token 值见 `tokens/skins.json`、`tokens/accents.json`、`tokens/primitives.json → derivedAlphas`。本篇定义**角色与规则**。

## 配色哲学

**中性玻璃**：界面是半透明的磨砂玻璃叠在中性画布上，靠 hairline 与柔和投影分层；品牌个性由一个克制的强调色表达，内容（封面 / 书页 / 专辑图）才是色彩的主角。

推论规则：

1. **不用色块背景堆叠元素**。层次通过留白、hairline、卡片浮起表达；不在信息层级之间插入纯色背景条。
2. **elevation 全局禁用**（`surfaceTint: transparent`、`applyElevationOverlayColor: false`）——Material 的色调叠加会把中性面弄脏。
3. **避免中灰画布**（#F0–#F5 段）——在白卡片旁显"脏"。画布用坡道端点值。

## 语义角色

### 表面坡道（皮肤提供，四档）

| 角色 | 用途 |
|---|---|
| `canvas` | 页面底布（Scaffold 背景） |
| `surface` | 常驻面：列表区、导航底栏、卡片 |
| `elevated` | 浮层：对话框、菜单、弹层 |
| `overlay` | 反馈面：snackbar、tooltip |

### 玻璃 token（浮面的半透明语言）

`surface`（72%）用于一般玻璃面；`strongSurface`（87–90%）用于需要更高遮罩的 chrome（对话框、底栏、侧栏）；`border` / `innerHighlight` / `shadow` / `blur` / `strongBlur` 配套使用。

**chromeSurface**：`strongSurface` 收敛到 80% 不透明度，用于常驻玻璃 chrome（侧栏、底栏）。

### 文字三档

`primaryText` / `secondaryText` / `mutedText`。**层级 = 字重 × 颜色**，muted 档用于空态图标、次要说明、元信息。

### 派生 alpha（全品牌唯一来源）

边框、hairline、subtle 填充、状态层、选中、barrier、destructive 的透明度**只能**取自 `tokens/primitives.json → derivedAlphas`。实现中发现缺档 → 提规范变更，不私造数值。

## 强调色规则

- 强调色轴与皮肤正交；产品各自持有（开听珊瑚、开卷暖橙），见 `tokens/accents.json`。
- 只用于：**选中态、进度、主操作**。同区最多一个主强调。
- `onAccent`：亮度估算——深底白字，浅底 `#1C1C22`。
- 低透明度派生固定：指示器 10–14%、chip 选中 9%、列表选中 3.5%、focus 环 16%。

## 皮肤规则

- 皮肤拥有明暗；**跟随系统**是伪皮肤（解析规则见 `tokens/skins.json → systemPseudoSkin`）。
- 实色皮肤（纯净）：`blur=0` 跳过 BackdropFilter、`shadowScale=0` 无投影——组件读 token 即免费获得，**禁止**在组件里写 `if (skin == 'pure')`。
- 皮肤切换过渡：`paletteTransitionMs`（420/240/520），只对颜色与透明度做插值，不动布局。

## 内容层配色（扩展点）

产品可在内容区持有独立色板（开卷：阅读主题纸白/羊皮纸/深色/纯黑与批注高亮色；开听：封面氛围渐变）。规则：

1. 内容色板不影响 chrome 配色（两者独立切换）；
2. 覆盖在内容上的 chrome 可从内容色板取色以保证可读性（开卷阅读器工具条），此为**已登记分叉**；
3. 内容色板仍须遵守"不用色块切分层级"与对比度直觉（正文/背景对比 ≥ 7:1 的目标）。
