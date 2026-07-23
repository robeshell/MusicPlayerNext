# 选择条与 Chips（ChoiceStrip / ChoiceOption）

- **用途**：过滤、单选分段、设置中的并列选项。
- **不用**：多行表单选择（用 ListRow + check）。
- **参考实现**：kaiting `sound_components.dart → SoundChoiceStrip`；kaijuan `app_components.dart → AppChoiceStrip`、阅读器 `_SegmentedChoices`。

## 解剖与 Metrics

无边框胶囊条：横排滚动（默认）或 Wrap。

| 部位 | 值 |
|---|---|
| 高度 | 32 |
| 内边距 | 11h |
| 圆角 | pill |
| 间距 | 8 |
| 图标 | 15（可选，前导 6 间距） |
| 文字 | 12；选中 w700 / 未选 w600 |

## Token 映射与状态

| 状态 | 背景 | 前景 |
|---|---|---|
| default | 前景 2.5% | secondary × 0.82 |
| selected | accent 9% | accent |
| disabled | 前景 2.5% | muted 45% |

## 交互

- 选中过渡 160ms；单选语义（`selected`）。
- 阅读器等覆盖在内容上的场景：前景可取内容色板（已登记分叉），形状/高度/间距不变。

## 与 Material Chip 的关系

Theme 层已把 Chip 配成同语言（pill、无 checkmark、选中 accent 9%）。**优先用 ChoiceStrip**；仅在语义必须是 Chip 控件时（InputChip 等）用 Material Chip。

## 验收锚点

- 高 32、胶囊、选中 accent@0.09 底 + accent 字 w700；
- 无边框、无 checkmark 图标。
