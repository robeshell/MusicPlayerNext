# 列表行（ListRow / CheckRow）

- **用途**：设置项、弹层操作项、结构化列表。
- **参考实现**：kaiting `sound_components.dart → SoundListRow / SoundCheckRow`；kaijuan `app_components.dart → AppListRow / AppCheckRow`。

## 解剖

```
[leading 槽32] 10 [标题 13.5 w600 / 副题 11.5 secondary] 10 [trailing]
```

## Metrics

| 部位 | 值 |
|---|---|
| minHeight | 54（设置页 64 / 紧凑 58） |
| padding | 14h / 6v |
| leading 槽 | 32 宽居中 |
| 标题 | 13.5 w600，单行省略 |
| 副题 | 11.5 secondary，单行省略 |

## Token 映射与状态

| 状态 | 背景 | 前景 |
|---|---|---|
| default | 透明 | primary |
| hovered | 前景 3.5% | — |
| focused | 前景 5% | — |
| selected | 前景 5% | 内容可叠加 accent |
| disabled | — | muted 50% |

## CheckRow 变体

leading 为 checkbox 图标（20px）：选中 accent 实心 / 未选 muted 空心；点击整行切换；`selected` 与勾选态一致。

## 设置分组中的行

- 分组卡片内行间用 hairline（indent 14）分隔，见 `patterns/settings-page.md`；
- **选中态不得用整行填充块**——用行内 check / accent 文字表达。

## 交互

- 整行可点（InkWell 透明叠加）；无 onTap 时不注册 button 语义。
- destructive 行：图标与文字 error 色。

## 验收锚点

- minHeight 54、标题 13.5 w600、副题 11.5；
- 行内不出现 elevation / 阴影。
