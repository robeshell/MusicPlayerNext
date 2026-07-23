# 排版规范

> 数值见 `tokens/primitives.json → typography`。

## 原则

**层级靠字重与颜色驱动，不靠字号堆叠。** 正文与 UI 文字集中在 11.5–14px 的小区间，用 w600→w700→w800 与 primary→secondary→muted 表达主次；只有页面标题使用大字号 + 负字距。

## 字族

- 主字族：`.SF Pro Text`
- 回退栈：`PingFang SC → Microsoft YaHei → Noto Sans CJK SC → Roboto → sans-serif`
- 不打包字体文件，全平台用系统字体。
- 内容层（开卷书页正文）可有独立字体栈与字号体系（Georgia/宋体等），属 L0 扩展，不受本篇约束。

## 字重阶梯

| 角色 | 字重 | 颜色档 |
|---|---|---|
| 展示 / 页标题 | w800 | primary，负字距 |
| 强强调（选中导航、主按钮、行标题） | w700 | primary 或 accent |
| 强调（正文强调、次级按钮、chip） | w600 | primary / secondary |
| 正文 | w400 | primary |
| 辅助说明 | w400 | secondary / muted |

## 关键字号（壳层）

| 场景 | 字号 | 字重 | 备注 |
|---|---|---|---|
| 页标题 | 26（紧凑）/ 28 | w800 | letterSpacing −0.55 |
| headlineMedium | 默认阶梯 | w800 | letterSpacing −0.55 |
| titleLarge | 默认阶梯 | w800 | letterSpacing −0.25 |
| 行标题 | 13.5–14 | w600–700 | |
| 行副题 / 元信息 | 11.5–12.5 | w400–500 | secondary/muted，行高 1.45 |
| 导航标签 | 10.5 | 选中 w800 / 未选 w600 | |
| chip 标签 | 12 | 选中 w700 / 未选 w600 | |
| 对话框标题 | titleLarge | w800 | |
| 按钮 | labelMedium | w700 | |

## 规则

1. 大标题（≥22px）一律负字距；正文与行文字不加字距。
2. `bodySmall` 默认染 secondary 色（TextTheme 层约定）——实现时注意：不显式设样式的小字自动变灰是**特性**，需要 primary 色的小字必须显式指定。
3. 数字与进度标签可用 tabular figures；中英文混排不额外加空格（交给系统排版）。
4. 截断：行标题单行省略；说明文字最多两行；对话框标题单行省略。
