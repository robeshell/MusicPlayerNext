# 验收清单

> 实现完成后逐项自检。A 类为可断言数值（代码审查/测试可判），B 类为人工巡检。

## A. 静态与数值锚点

- [ ] 静态分析零告警（`flutter analyze`）
- [ ] 全局 `splashFactory: NoSplash.splashFactory`、`applyElevationOverlayColor: false`、`surfaceTint: transparent`
- [ ] 圆角：对话框 20 / 弹层 18 / 菜单 12 / 卡片 14 / 控件 10 / 按钮与 chip 胶囊
- [ ] 按钮：最小 36、胶囊、iconSize 17；IconButton 40 正圆、图标 20
- [ ] chip：高 32、选中 accent@0.09 底 + accent 字 w700、无边框无 checkmark
- [ ] 列表行：minHeight 54、标题 13.5 w600、副题 11.5
- [ ] 输入框：r10、subtle 填充、聚焦 2px accent
- [ ] 滑杆：轨道 3、拇指 r6；进度圈 24px/2px 且无硬编码色
- [ ] 开关：轨道 40×24、拇指 18、选中 accent/onAccent、未选 border/secondary、无描边、无 `Switch.adaptive`
- [ ] 底栏：56px、图标 21、标签 10.5 选中 w800
- [ ] 对话框：maxWidth 520、barrier 黑 38%/62%；sheet：maxWidth 760、把手 38×4
- [ ] 锚定菜单：宽 252；<680px 自动退化为底部弹层
- [ ] 字族 `.SF Pro Text` + 五个回退；页标题 26/28 w800 负字距 −0.55
- [ ] 代码中无字面色值泄漏（grep `Color(0x` 应只出现在 theme 层与内容层扩展）
- [ ] 旧外观存储迁移有单元测试

## B. 人工巡检

- [ ] 三皮肤 × 至少两个强调色：书架/库面/设置/主要浮层全过一遍
- [ ] 纯净皮肤：所有浮面实色无模糊无投影（组件未硬编码模糊）
- [ ] 深夜皮肤：浮层 barrier 明显、玻璃面层次可读
- [ ] 跟随系统：切换系统外观，App 即时跟随
- [ ] 窄窗（<680）菜单变底部弹层；宽窗锚定弹层不错位（靠右边缘自动内收、底部自动上翻）
- [ ] 桌面：hover 反馈可见、键盘 Tab 焦点环 2px accent、tooltip 450ms
- [ ] 移动：底栏玻璃下内容可延伸、末行不被遮挡（底部留白 140）
- [ ] 对话框：矮内容收缩包裹、高内容仅内容区滚动
- [ ] 空态/加载/错误三态符合反馈规范
- [ ] 内容层（若有）：切换内容主题不影响 chrome；chrome 覆盖内容时可读
