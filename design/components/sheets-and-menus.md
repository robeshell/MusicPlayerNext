# 底部弹层与菜单（BottomSheet / Menu）

- **用途**：移动优先的操作集合、详情面板、上下文菜单。
- **参考实现**：kaiting `sound_components.dart → showSoundBottomSheet / SoundMenuButton / showSoundMenu`；kaijuan `app_components.dart → showAppBottomSheet / AppMenuButton / showAppMenu`。

## 底部弹层（BottomSheet）

### Metrics

| 部位 | 值 |
|---|---|
| 圆角 | 顶角 18（sheet 档） |
| 拖拽把手 | 38×4 胶囊，secondary 38–45%，距顶 7 |
| maxWidth | 760（宽屏居中） |
| 阴影 | blur 28 × scale，offset (0,−8) |
| barrier | black 38%（浅）/ 62%（深） |

### Token 映射

表面 = glass.strongSurface + glass.border；内容区顶 padding 14（避开把手）。

## 菜单（Menu）——自适应，同一数据模型两种呈现

**数据模型**：`MenuAction<T>{ value, label, icon, subtitle?, selected, enabled, destructive, dividerBefore }`。

| 窗口宽度 | 呈现 |
|---|---|
| < 680 | 底部弹层（行高 ≥52，padding 20h，最高 72% 视口，SafeArea） |
| ≥ 680 | 锚定玻璃弹层：宽 252，r12（menu 档），shadow blur 24 offset (0,8)，自动上下翻 |

### 菜单行

| 部位 | 值 |
|---|---|
| 行高 | 紧凑 52 / 宽屏 46 |
| 图标 | 19px，槽宽 24 |
| 标签 | 14 w600；副题 11.5 secondary |
| 选中 | 前景 5.5% 底 + accent 前景 + 右侧 check 18px |
| destructive | error 前景 |
| 分隔 | dividerBefore → hairline（indent 16） |
| 菜单标题 | 12–12.5 w600 secondary + hairline 分隔 |

### 触发器（MenuButton）

- 默认 more_horiz 21px 图标钮；支持自定义 child（hover 前景 4%）。
- 无可用项时禁用。

## 禁止事项

- 禁止裸用 Material PopupMenuButton 默认样式（主题已配，但自适应菜单优先）；
- 禁止菜单内嵌套滚动视图不收缩（ListView 必须 shrinkWrap）。

## 验收锚点

- sheet 顶角 r18、把手 38×4、maxWidth 760；
- 锚定菜单宽 252、<680px 自动退化为底部弹层。
