# CHANGELOG.md — 变更日志

## [0.1.0] — 2026-07-09

### Added — Phase 0: 项目初始化与 4Tab 导航框架

- 应用基础配置（bundleName: com.example.beadstudio, version 1.0.0）
- 浅色/深色主题颜色系统（20个语义色）
- 中文字符串资源（30个文本资源）
- 全局常量文件（Constants.ets）
- Index.ets 闪屏页（入场动画 + 自动跳转）
- MainPage.ets 4Tab 导航容器（首页/创作/广场/我的）
- 4个 Tab 占位页面（HomePage, CreatorPage, SquarePage, MinePage）
- 8个路由子页占位（AICreatePage, ImageImportPage, PatternEditorPage, WorkDetailPage, UserProfilePage, MyWorksPage, MyFavoritesPage, SettingsPage）
- 页面路由注册（main_pages.json）

### Fixed

- Index.ets `@State opacity` 与内置属性冲突 → 重命名为 `textOpacity`
- MainPage.ets 对象字面量类型 → 显式 `interface TabItemData`
- 不支持的 SymbolGlyph 图标 → 替换为 Text emoji
- `.renderMode(0)` API 移除
- main_pages.json 移除 Tab 内嵌页面（HomePage/CreatorPage/SquarePage/MinePage）
- 8个路由页面缺少 `@Entry` 装饰器

### Docs

- 创建 CLAUDE.md 开发规范（19 个章节，438 行）
- 创建 docs/PROJECT.md 项目总览
- 创建 docs/ROADMAP.md 开发路线图（9 个 Phase）
- 创建 docs/ARCHITECTURE.md 架构设计
- 创建 docs/CHANGELOG.md 变更日志
- 创建 docs/TODO.md 任务看板
- 创建 docs/REFERENCES.md 官方文档索引（含已验证/不支持 API 清单）

### Docs — Phase 0.5: 设计系统建设

- 创建 docs/UI_DESIGN.md 专业级设计系统（8 个章节：设计理念/色彩/布局/组件/参数/动画/图标/页面方案）
- 创建 docs/DEVELOPMENT_RULES.md 开发流程规范（7 步开发流程/禁止事项/审查清单）
- CLAUDE.md 新增"专业级 UI 设计规范"章节（设计参数/动画/图标/适配）
- CLAUDE.md 新增"配套文档索引"章节
- 修正所有文档中的 `@Trace` 装饰器错误 → 统一为 ArkTS V1 状态管理（@Observed + @ObjectLink）
- ARCHITECTURE.md 修正状态管理策略表
- TODO.md 新增 Phase 0.5 设计阶段任务
