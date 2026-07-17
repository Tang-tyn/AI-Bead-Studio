# CHANGELOG.md — 变更日志

## [0.2.0] — 2026-07-17

### Added — Phase 1: 数据模型与调色板系统

**Model 层（5 文件）**
- BeadColor.ets — 拼豆颜色模型（id=色号, hexColor, rgb, lab）
- ColorPalette.ets — 调色板模型（colors[], getColorById, getColorCount）
- GridCell.ets — 网格单元格（极简：仅 colorId）
- BeadPattern.ets — 拼豆图纸（cells[row][col] + createEmptyGrid 工厂方法）
- Project.ets — 项目包装（pattern + 来源 + ProjectStatus 枚举）

**调色板系统**
- MardPalette.json (rawfile) — MARD 221 色完整数据（37KB）
- MardPalette.ets — JSON 加载器
- MardPaletteService.ets — 数据服务（查询/初始化，单例）

**颜色计算引擎**
- ColorUtils.ets — hex↔rgb, sRGB→XYZ(D65)→Lab, Delta E 76 色彩距离
- ColorMappingService.ets — Lab + Delta E 最近邻颜色匹配引擎

**测试页面**
- PaletteTestViewModel.ets — 测试页状态管理
- PaletteTestPage.ets — 221 色 Grid 展示 + Delta E 匹配测试

**设计决策**
- DD-008: V1 MARD 唯一品牌标准（移除多品牌支持）
- DD-009: Lab + Delta E 76 颜色匹配（升级自 RGB 距离）

### Changed
- BeadColor.ets — 移除 brand/code 字段，id 即色号
- ColorPalette.ets — 移除 brand 字段
- CreatorPage.ets — 新增"MARD 色卡测试"入口按钮

### Removed
- StandardPalette.ets — 被 MardPalette.ets 替代

---

## [0.1.0] — 2026-07-09

### Added — Phase 0: 项目初始化与 4Tab 导航框架

- 应用基础配置（bundleName: com.example.beadstudio, v1.0.0）
- 浅色/深色主题颜色系统（20 个语义色）
- 中文字符串资源（30 个文本资源）
- 全局常量 Constants.ets
- Index.ets 闪屏页（入场动画 + 自动跳转）
- MainPage.ets 4Tab 导航容器（首页/创作/广场/我的）
- 4 个 Tab 占位页面 + 8 个子页占位
- 页面路由注册（main_pages.json）

### Fixed
- @State opacity 与内置属性冲突 → textOpacity
- 对象字面量类型 → 显式 interface
- 不支持的 SymbolGlyph → Text emoji
- .renderMode(0) 移除
- main_pages.json 移除 Tab 内嵌页面
- 路由页面缺少 @Entry 装饰器

### Docs
- CLAUDE.md（20 章节，461 行）
- docs/PROJECT.md / ARCHITECTURE.md / ROADMAP.md
- docs/UI_DESIGN.md / UI_PHASE0_DESIGN.md / PATTERN_EDITOR_DESIGN.md
- docs/DESIGN_DECISION_LOG.md（9 个设计决策）
- docs/DEVELOPMENT_RULES.md / REFERENCES.md
- docs/PROJECT_STATUS.md / CHANGELOG.md / TODO.md
