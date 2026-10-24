# CHANGELOG.md — 变更日志

## [Unreleased] — 2026-10-24

### Added
- 线条图模式（图纸风格切换，默认照片模式不变）：ImageProcessingService 新增 ImageSamplingMode 枚举与众数量化桶采样（16 级/通道）+ 暗线优先（亮度<35、占比≥10%）+ 自动裁白边（行/列投影自适应阈值，取峰值 5%）+ 内容框宽高比适配（短维居中留白填白格，总格数不变）+ 色彩精简（保留前 6 主色归并）；ImportSession/ViewModel/Page 全链路传参。经五轮迭代（含暗部膨胀方案试做并回滚）后冻结，29×29 残留细节问题归入编辑器阶段
- 成品尺寸厘米提示：预设按钮 ≈X cm 小字 + 动态「成品约 X × Y cm（按 5mm 拼豆）」
- docs/TODO.md — 新增「增强：图片剪裁（轻量版）」排期条目（Phase 3 收尾后、Phase 6 之前）：固定比例预设 + 可拖动剪裁框，剪裁区域作为采样偏移传入 ImageProcessingService，不动核心映射算法
- docs/TODO.md — 新增「增强：透明度支持（最小方案）」：导入开关「透明→空格/白底」+ alpha<128 阈值判定 + 全透明错误提示 + 预览空格渲染；边缘杂色交由剪裁处理
- docs/TODO.md — 新增「增强：PNG 格内色号标注」：格子像素自适应 + 每格色号文本 + 明暗自适应文字色 + 小格子退回规则；仅动绘制层

### Changed
- 自动裁白边与宽高比适配推广至照片模式：照片同样裁掉纯白边、按内容比例适配网格，主体占满格子且不变形（采样算法本身不变）

### Verified
- Phase 3 模拟器验证：图库保存取消（提示「已取消保存到图库」、不崩溃、图库不新增）与重名处理（连续保存文件名唯一）通过（A/B 项）
- Phase 3 模拟器逐色核对通过（2026-10-24）：页面统计硬校验（总数=宽×高、各色相加=总数）、PNG 标题/图例/行列编号/网格线核对、抽样数格一致、58×58 换尺寸总数抽查（3364）通过 → Phase 3 模拟器验证全部收尾，仅剩真机项（无真机，挂起）
- `SDK component missing` 构建环境问题确认已解决（近期多轮 Build HAPs 正常），TODO 阻塞清零
- 透明空格验证项确认：V1 白底合成流程下 UI 无法触发 `colorId=''` 空格，该项挂起至编辑器阶段

---

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
