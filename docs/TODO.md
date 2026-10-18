# TODO.md — 任务看板

## 当前阶段：图片转图纸 V1 完善中

当前版本主流程：选择原图 → 设置尺寸 → 生成图纸 → 查看 MARD 色号与材料统计 → 导出 PNG。
完整图纸编辑器（逐格编辑、工具栏、撤销和手势）暂缓，不属于当前版本范围。

---

## Phase 1: 数据模型与调色板系统 ✅

- [x] Step 1: Model 数据层（5 文件）
- [x] Step 2: MARD 221 色数据接入
- [x] Step 3: ColorUtils（RGB/XYZ/Lab/DeltaE76）
- [x] Step 4: ColorMappingService（Lab 匹配引擎）
- [x] Step 5: 调色板测试页面
- [x] Step 6: 编译验证 + 文档更新

---

## Phase 2: 图片导入功能

- [x] photoAccessHelper 相册选择集成
- [x] 图片加载与尺寸边界检查（解码最长边限制为 2000px）
- [x] 导入参数配置界面（细节推荐 + 常用尺寸 + 自定义宽高；V1 固定 MARD 调色板）
- [x] ImageImportPage 主要 UI 与 Phase 3 数据交接
- [x] CompileArkTS / HAP 编译验证
- [ ] DevEco 模拟器/真机交互验证

---

## Phase 3: 拼豆图纸生成（核心）

- [x] ImageProcessingService（区域采样、Alpha 白底合成、MARD 颜色映射）
- [x] ImageImportViewModel（MARD 初始化、图纸与内存 Project 生成）
- [x] PixelMap 所有权交接、成功/失败/取消清理
- [x] 转换进度与取消请求
- [x] MARD 初始化完整性校验与生成任务状态隔离
- [x] API 24 HAP 编译验证
- [x] BeadGrid Canvas 静态预览（MARD 色号映射、缩放与自适应网格线）
- [x] 静态预览每格绘制细分线、每 5 格绘制加粗分隔线
- [x] 重置/离开时清除旧预览，并拒绝无效 Canvas 颜色值
- [x] 按 API 24 模拟器 `readPixels()` BGRA 实测修正 RGB 通道索引
- [x] 生成预览可返回尺寸设置并复用原图 PixelMap 重新生成
- [x] 当前图纸实际用色统计与色号图例（代码已接入；设备数据核对待做）
- [x] 独立 PNG 图纸导出（独立绘制尺寸、行列编号、图例与材料数量；系统文档保存位置）
- [x] 默认图库保存路径接入 API 24 系统图库确认 API；保留「保存到指定位置」文件选择器入口
- [x] PNG 图纸已由用户人工验收：成功保存到图库，图片颜色与内容显示正常
- [ ] 验证图库保存取消、重名处理及透明空格
- [x] API 24 模拟器验证 29→58→87→200 重生成、返回保留原图、取消恢复设置、重新选图后生成
- [x] 模拟器验证 116×116 图纸总数为 13,456；PNG 保存为 `BeadPattern_116x116.png`，系统识别为 `image/png` 并成功解码/打开（1240×1874）
- [ ] 模拟器逐色核对统计与图格一致，并检查 PNG 图例、编号和图纸视觉内容
- [ ] 真机复测颜色还原、统计/导出、静态预览性能、取消和 PixelMap 资源释放
- [ ] 修复本次 HAP 构建环境中的 `SDK component missing`：Hvigor 未能解析已安装的 API 24 SDK 组件；确认 SDK 安装/组件注册后再构建

## 暂缓：完整图纸编辑器

- [ ] EditorViewModel、PatternEditorPage、ToolBar
- [ ] 逐格画笔/橡皮/填充/吸色、撤销/重做
- [ ] 双指缩放、平移及编辑手势
- 设计参考保留在 `PATTERN_EDITOR_DESIGN.md`；本版本不据此搭建编辑器架构。

材料统计与 PNG 导出属于当前图片转图纸产品流程，不依赖编辑器。

---

## Phase 5: AI 图片创作

- [ ] AIService Provider 抽象
- [ ] AICreateViewModel
- [ ] AICreatePage 界面
- [ ] StyleSelector 组件
- [ ] 编译验证

---

## Phase 6: 项目管理与本地存储

- [ ] DatabaseHelper（RDB）
- [ ] StorageService 完整实现
- [ ] HomeViewModel + HomePage
- [ ] ProjectCard / EmptyState / ConfirmDialog
- [ ] 编译验证

---

## Phase 7: 广场社区

- [ ] CommunityService
- [ ] SquareViewModel + SquarePage（瀑布流）
- [ ] WorkDetailPage + CommentItem + WorkCard
- [ ] UserProfilePage
- [ ] 编译验证

---

## Phase 8: 个人中心与设置

- [ ] MinePage 完整实现
- [ ] MyWorksPage / MyFavoritesPage
- [ ] SettingsPage
- [ ] 编译验证

---

## Phase 9: 打磨与发布优化

- [ ] 全局动画优化
- [ ] 性能优化
- [ ] 错误处理完善
- [ ] 无障碍适配
- [ ] 发布准备

### Phase 9 子任务：图标体系替换

- [ ] 全局替换 Emoji 占位图标
- [ ] 使用 HarmonyOS SymbolGlyph（已确认支持的）或统一 SVG 图标资源
- [ ] 图标风格：线框（未选中）/ 填充（选中），统一 24vp
- [ ] 全局检查图标尺寸、颜色、间距符合 UI_DESIGN.md 规范
- [ ] 涉及页面：MainPage TabBar、HomePage、CreatorPage、SquarePage、MinePage

---

## 已知问题

| 优先级 | 问题 | 状态 |
|--------|------|------|
| 低 | Tab 占位页面 UI 简陋 | 各 Phase 实现时按 UI_DESIGN.md 重写 |
| 低 | Emoji 图标作为占位，非正式 UI | Phase 9 统一替换为 SymbolGlyph 或 SVG |
| 低 | MardPalette.ets 中 @kit.LocalizationKit 未确认 | Phase 1 测试通过，待正式环境验证 |
