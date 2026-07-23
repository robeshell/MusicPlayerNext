# 浮层模式（Overlays）

## 层级（z 序，低到高）

1. 页面内容
2. 粘性条 / 阅读器 chrome
3. 常驻 chrome（底栏 / 侧栏）
4. 底部弹层（sheet）
5. 对话框（dialog）
6. 锚定菜单 / popup
7. snackbar / tooltip

规则：高层级可覆盖低层级；同层级不叠加（新 sheet 进栈前旧 sheet 必须退出；snackbar 新顶旧）。

## Barrier

| 浮层 | 浅色 | 深色 |
|---|---|---|
| 对话框 / 底部弹层 | black 38% | black 62% |
| 锚定菜单 | 透明（点击外部关闭） | 同 |

## 自适应规则

| 模式 | 窄（<680px） | 宽（≥680px） |
|---|---|---|
| 菜单 | 底部弹层 | 锚定 252px 玻璃弹层 |
| 详情面板 | 底部弹层（maxWidth 760 居中） | 同左或内联面板 |
| 对话框 | maxWidth 520，视口内边距 20h/24v | 同左 |

## 浮面通则

- 浮面 = GlassSurface strong：strongSurface + border + shadow × shadowScale +（可选）模糊；
- **模糊按面选用**：浮面（对话框/菜单/弹层/底栏）模糊；重复的行/卡片不模糊（`blur: false`）；blur=0 的皮肤自动跳过；
- 浮面圆角：对话框 20 / 弹层 18 顶角 / 菜单 12；
- 浮层出现动画 140ms 淡入（锚定菜单）或系统默认（sheet/dialog）；消失不晚于 160ms。

## 手势

- sheet 下滑关闭；snackbar 下滑关闭；
- 锚定菜单点击外部关闭；
- 桌面 Esc 关闭顶层浮层（框架默认）。
