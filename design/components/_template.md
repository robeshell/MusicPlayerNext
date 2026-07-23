# 组件规范模板

> 每个组件一篇，放在 `components/`。命名用中性名（各产品实现可加前缀：开听 `Sound*`、开卷 `App*`）。

```markdown
# 组件名（NeutralName）

- **用途**：什么时候用。
- **不用**：什么时候不该用（反例）。
- **参考实现**：kaiting <文件> → <类名>；kaijuan <文件> → <类名>。

## 解剖

分区结构（ASCII 或列表），标注每部分的 token 来源。

## Metrics

| 部位 | 值 |
|---|---|
| 高度 / 内边距 / 圆角 / 字号字重 / 图标尺寸 | 精确数值 |

## Token 映射

| 部位 | token |
|---|---|
| 背景 / 边框 / 文字 / 阴影 | 语义 token 路径（如 glass.strongSurface、derivedAlphas.hairline） |

## 状态

| 状态 | 背景 | 前景 | 其他 |
|---|---|---|---|
| default / hovered / pressed / focused / disabled / selected | 叠加或色值 | | |

## 交互

点击 / 键盘 / tooltip / 动画（时长曲线）。

## 变体

如 destructive、primary、compact——各自与默认态的差异。

## 禁止事项

实现时最容易犯的错（硬编码、elevation、水波纹…）。

## 验收锚点

可断言的数值清单（供实现后自检）。
```
