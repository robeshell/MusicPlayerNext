# 输入控件（TextField / Slider / Switch / Checkbox / Radio / Dropdown）

- **参考实现**：kaiting `sound_theme.dart`（inputDecoration / slider / switch / checkbox / radio / dropdownMenu 子主题）；kaijuan `lib/core/theme/app_theme.dart`。

## 文本输入（TextField）

| 部位 | 值 |
|---|---|
| 填充 | subtle（前景 4.5%/5.5%） |
| 圆角 | 10（control 档） |
| 边框 | 常态 border；聚焦 2px accent；错误 error（聚焦 2px） |
| 内边距 | 14h / 14v，isDense |
| 标签 | secondary w600；浮动标签 accent w700 |
| 提示 | secondary 70% |
| 前后图标 | secondary |

规则：对话框内输入框 autofocus + Enter 提交（见对话框规范）；搜索框可有独立更矮的紧凑变体，但填充/圆角/聚焦规则不变。

## 滑杆（Slider / 进度条）

| 部位 | 值 |
|---|---|
| 轨道 | 高 3；激活 accent / 未激活 border |
| 拇指 | 半径 6 圆，accent |
| 按压 overlay | accent 12%，半径 14 |
| 数值标签 | 不显示 |

只读进度条复用同语言（轨道 3、无拇指或拇指 5）。

## 开关（Switch）

选中：轨道 accent、拇指 onAccent；未选：轨道 border、拇指 secondary；无轨道描边。

## 勾选 / 单选（Checkbox / Radio）

- Checkbox：圆角 5、1.4px border 描边、选中 accent 底 + onAccent 勾；
- Radio：选中 accent；均 compact 密度。

## 下拉（DropdownMenu）

输入部分同 TextField；菜单部分 elevated 面 + r12 + border（同菜单规范）。

## 禁止事项

- 禁止无填充的下划线输入框（M1 风格）；
- 禁止滑杆拇指带阴影/ elevation。

## 验收锚点

- 输入框 r10、填充 subtle、聚焦 2px accent；
- 滑杆轨道 3 / 拇指 6；checkbox r5。
