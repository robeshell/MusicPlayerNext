# 形状 · 阴影 · 分隔 · 动效 · 交互状态层

> 数值见 `tokens/primitives.json`（radii / motion / derivedAlphas / tapTargets）。

## 圆角

| 刻度 | 值 | 用途 |
|---|---|---|
| control | 10 | 按钮（配合 pill）、输入框、小控件、导航指示器 |
| card | 14 | 卡片、封面框、设置分组卡 |
| menu | 12 | 菜单、弹层、snackbar |
| sheet | 18 | 底部弹层（仅顶角） |
| dialog | 20 | 对话框 |
| pill | 999 | 胶囊：按钮、chip、滑杆、滚动条、拖拽把手 |
| checkbox / tooltip | 5 / 8 | 特例 |

规则：嵌套圆角外大内小（外 14 内 10 级差）；图片封面随容器卡片档。

## 阴影与深度

- **不用 Material elevation**。深度 = 玻璃阴影 token × `effects.shadowScale`：
  - 浮面默认：blur 24（strong 34），offset (0,10)；
  - 底部弹层：blur 28，offset (0,−8)；
  - 导航底栏：blur 18，offset (0,−6)；
  - 锚定菜单：blur 24，offset (0,8)；
  - 封面微浮起：blur 10 × scale，offset (0,3)。
- 实色皮肤（shadowScale=0）自动无影。
- 封面 / 缩略图小于 96px 时可省略投影（重复元素省渲染）。

## 分隔

- 一级分隔：hairline（1px，`derivedAlphas.hairline`）。
- 分组卡片内部行间分隔：hairline，indent 14。
- 禁止用 ≥4px 的色带做分隔。

## 交互状态层（State Layer）

全局 **NoSplash**：禁水波纹与 highlight 色块；反馈一律用透明度叠加：

| 状态 | 叠加 |
|---|---|
| hovered | 前景 5.5–6.5% |
| pressed | 前景 10% |
| focused | accent 16% 叠加 + 2px accent 描边（键盘） |
| disabled | 前景/文字 38–48% 透明度，不叠加 |
| selected | 面：前景 5–5.5%；指示：accent 系（见配色规范） |

destructive 三档：rest error 8% / hover·focus 12% / pressed 16%（文字 error 本色）。

## 触控目标

按钮 ≥36px、图标钮 40px 正圆、列表行 ≥46px、chip 32px 高。桌面不缩小目标，用 hover 反馈补偿精度。

## 动效

| 场景 | 时长 | 曲线 |
|---|---|---|
| 状态反馈（hover/press/选中） | 140–160ms | easeOut / easeOutCubic |
| 浮层进出 | 140ms 淡入（锚定菜单）；系统默认（sheet/对话框） | easeOut |
| 皮肤 / 配色切换 | 按皮肤 240–520ms | 只对颜色插值 |
| 环境动效（氛围背景等） | ≥14s | 线性/缓动循环 |

- reduced-motion：环境动效按 `effects.motionStrength` 衰减至近 0；状态反馈动效保留。
- 动画只动 transform / opacity / color；禁止动画触发布局（reflow）。

## 平台交互差异

| 场景 | 桌面 | 触屏 |
|---|---|---|
| 列表激活 | 单击选中、双击/Enter 激活 | 单击激活 |
| 次级操作 | 右键 = 长按菜单 | 长按菜单 |
| tooltip | 450ms 悬停 | 不用 |
| 焦点环 | 键盘导航必须可见 | 不显示 |

菜单呈现按宽度自适应（<680px 底部弹层 / ≥680px 锚定弹层），见 `patterns/overlays.md`。
