# TODO.md — 任务看板

## 当前阶段：Phase 1 Step 2（调色板数据）

---

## 待完成任务

### Phase 1: 数据模型与调色板系统
- [x] Step 1: Model 数据层 — BeadColor/ColorPalette/GridCell/BeadPattern/Project（5文件, 482行）
- [ ] Step 2: HamaPalette 数据
- [ ] Step 2: PerlerPalette 数据
- [ ] Step 2: ArtkalPalette 数据
- [ ] Step 3: ColorUtils（RGB↔Hex，色彩距离）
- [ ] Step 4: ColorMappingService（最近邻匹配）
- [ ] Step 5: PaletteListPage 测试页面
- [ ] Step 6: PaletteDetailPage 测试页面
- [ ] 集成验证：编译通过 + 端到端测试
- [x] PatternEditorPage 架构设计 → 已确认
- [x] docs/PHASE1_PLAN.md 开发计划输出
- [x] docs/DESIGN_DECISION_LOG.md 创建（7个设计决策）
- [x] docs/PROJECT_STATUS.md 创建（项目状态总览）
- [x] 进入 Phase 1 编码
- [ ] PreferencesHelper 基础读写

### Phase 2: 图片导入功能
- [ ] photoAccessHelper 集成
- [ ] 图片加载与尺寸检查
- [ ] 导入参数配置界面
- [ ] ImageImportPage 完整实现

### Phase 3: 拼豆图纸生成（核心）
- [ ] ImageProcessingService（缩放/像素化/采样）
- [ ] ImageImportViewModel（转换流水线）
- [ ] BeadGrid Canvas 组件
- [ ] 转换进度指示
- [ ] 预览确认→保存流程

### Phase 4: 图纸编辑器
- [ ] EditorViewModel（工具/撤销/缩放）
- [ ] PatternEditorPage 全屏编辑器
- [ ] ToolBar 工具栏
- [ ] 手势处理
- [ ] MaterialList 材料统计
- [ ] ExportService

### Phase 5: AI 图片创作
- [ ] AIService Provider 抽象
- [ ] AICreateViewModel
- [ ] AICreatePage 界面
- [ ] StyleSelector 组件

### Phase 6: 项目管理与本地存储
- [ ] DatabaseHelper（RDB）
- [ ] StorageService 完整实现
- [ ] HomeViewModel + HomePage 完整实现
- [ ] ProjectCard / EmptyState / ConfirmDialog

### Phase 7: 广场社区
- [ ] CommunityService
- [ ] SquareViewModel + SquarePage（瀑布流）
- [ ] WorkDetailPage
- [ ] CommentItem + WorkCard
- [ ] UserProfilePage
- [ ] 发布作品

### Phase 8: 个人中心与设置
- [ ] MinePage 完整实现
- [ ] MyWorksPage / MyFavoritesPage
- [ ] SettingsPage

### Phase 9: 打磨与发布
- [ ] 全局动画优化
- [ ] 性能优化
- [ ] 错误处理完善
- [ ] 无障碍适配
- [ ] 应用商店发布

---

## 已完成任务

### Phase 0: 项目初始化与 4Tab 导航框架
- [x] 项目基础配置
- [x] 深浅色主题
- [x] 字符串资源
- [x] Constants.ets
- [x] Index.ets 闪屏页
- [x] MainPage.ets 4Tab 容器
- [x] 4 个 Tab 占位页面
- [x] 8 个路由子页占位
- [x] main_pages.json
- [x] 编译错误修复
- [x] 项目规范文档

---

## 已知问题

| 优先级 | 问题 | 状态 |
|--------|------|------|
| 低 | 当前 Tab 占位页面 UI 简陋 | 功能验证通过后统一重构 |
| 低 | SymbolGlyph 用 emoji 代替 | 后续替换为专业图标 |
