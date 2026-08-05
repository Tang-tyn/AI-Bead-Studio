# TODO.md — 任务看板

## 当前阶段：Phase 1 已完成 → 等待 Phase 2

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

- [ ] photoAccessHelper 相册选择集成
- [ ] 图片加载与尺寸边界检查
- [ ] 导入参数配置界面（网格尺寸/调色板选择）
- [ ] ImageImportPage 完整 UI 实现
- [ ] 编译验证

---

## Phase 3: 拼豆图纸生成（核心）

- [ ] ImageProcessingService（缩放/像素化/采样）
- [ ] ImageImportViewModel（完整转换流水线）
- [ ] BeadGrid Canvas 组件
- [ ] 转换进度指示
- [ ] 预览确认→保存流程
- [ ] 编译验证

---

## Phase 4: 图纸编辑器

- [ ] EditorViewModel（工具/撤销/缩放）
- [ ] PatternEditorPage（全屏编辑器）
- [ ] ToolBar 工具栏
- [ ] 手势处理（点击/长按/双指缩放）
- [ ] MaterialList 材料统计
- [ ] ExportService（PNG/JSON/CSV）
- [ ] 编译验证

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
| 低 | MardPalette.ets 中 @kit.LocalizationKit 未确认 | Phase 1 测试通过，待正式环境验证 |
