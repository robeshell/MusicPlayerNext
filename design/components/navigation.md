# 导航（NavigationBar / SideRail）

- **用途**：顶层目的地切换（书架/书库/设置、曲库/搜索/设置…）。
- **参考实现**：kaiting `sound_components.dart → SoundNavigationBar`、`app_shell.dart`；kaijuan `app_components.dart → AppNavigationBar`、`app_shell.dart → _SideRail`。

## 底栏（移动壳 / 紧凑窗口）

### Metrics

| 部位 | 值 |
|---|---|
| 栏高 | 56（嵌入态 46）+ SafeArea |
| 图标 | 21 |
| 标签 | 10.5；选中 w800 / 未选 w600 |
| 项内边距 | 3h |

### Token 映射

- 表面：`chromeSurface`（strongSurface @80%）+ 顶 hairline，阴影 blur 18 offset (0,−6)；
- 选中：accent 图标与标签；未选：onSurfaceVariant。
- 标签颜色过渡 160ms easeOutCubic。

### 规则

- 目的地 3–5 个，图标+短标签（2–4 字）；
- 选中/未选图标可同形（开卷）或双态（开听），但尺寸一致；
- 底栏常驻，内容底部留白见 `patterns/app-shell.md`。

## 侧栏（桌面壳）

### Metrics

| 部位 | 值 |
|---|---|
| 宽度 | 216（medium）/ 236（wide）；开卷列表轨 220 |
| 行高 | ≥40 |
| 行圆角 | 10（control 档） |
| 品牌字 | 17 w800，负字距 −0.35 |

### Token 映射

- 表面：`chromeSurface` + 右 hairline，全高（延伸到标题栏下方，避让交通灯）；
- 选中行：accent 10% 胶囊底 + accent 图标 + primary 标签 w700；
- 未选行：secondary 图标与标签 w500；hover 前景 4.5%。

### 规则

- 两种形态：图标轨（开听）或列表轨（开卷）——产品可选，token 一致；
- 侧栏不透明堆叠内容时模糊可省（无内容从其下滚过），保持 chromeSurface 即可。

## 验收锚点

- 底栏 56px、图标 21、标签 10.5 且选中 w800；
- 侧栏选中 = accent 10% 胶囊（r10）。
