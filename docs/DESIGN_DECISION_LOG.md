# DESIGN_DECISION_LOG.md — 设计决策日志

> 记录项目中所有重要的架构/UI/技术决策。
> 每个决策有唯一编号（DD-XXX），包含背景、决策内容、原因、影响。
> 更新时机：任何重大调整发生时即时记录。

---

## 架构决策

### DD-001: HomePage 不承担主要创作入口

- **日期**：2026-07-09
- **决策者**：架构师 + 产品经理
- **背景**：需要明确首页和创作页的职责分工，避免功能重叠
- **决策**：
  - HomePage 定位为「项目中枢」：项目管理 + 灵感发现
  - 主要创作操作（AI创作、照片转图纸）统一走 CreatorPage
  - HomePage 可提供轻量快捷操作（如"新建项目"按钮），但不放大型创作 Banner
- **原因**：
  - 单一职责：每个页面聚焦一个用户目标
  - 避免混乱：用户不会在多个Tab看到相同的功能入口
  - 可扩展：未来添加新的创作方式只需修改 CreatorPage
- **影响范围**：HomePage、CreatorPage、MainPage Tab 架构

---

### DD-002: PatternEditorPage 使用 Canvas 而非组件化网格

- **日期**：2026-07-09
- **决策者**：架构师
- **背景**：拼豆图纸最大可达 200×200 = 40,000 个格子。如果用 40,000 个 @Component GridItem 渲染会直接卡死
- **决策**：
  - 使用 ArkUI Canvas 组件 + CanvasRenderingContext2D 逐格绘制
  - 配合视口裁剪（Viewport Culling）：只绘制屏幕可见区域的格子
  - 256 色以内的调色板索引，每个 Cell 只存 colorId (string)
- **原因**：
  - 性能：Canvas fillRect 调用 40,000 次 vs 创建 40,000 个组件，前者快 100x+
  - 内存：每个 Cell 对象 ~32 bytes，40,000 个 = 1.28MB，可接受
  - 手势：Canvas 上可以自由处理 tap/pinch/pan
- **替代方案（已否决）**：
  - Grid + GridItem：40,000 个组件会阻塞主线程
  - Image 像素级编辑：不够灵活，无法支持工具切换和撤销
- **影响范围**：PatternEditorPage、BeadGrid 组件、手势系统

---

### DD-003: AI 创作入口采用大卡片 + 风格标签前置

- **日期**：2026-07-09
- **决策者**：产品经理 + UI 设计师
- **背景**：AI 风格创作是 App 的差异化核心功能，需要在 UI 上体现其重要性
- **决策**：
  - CreatorPage 中 AI 创作使用大卡片设计（占 ~40% 可视空间）
  - 风格标签（Q版/漫画/像素/水彩/素描）前置在卡片内展示
  - 照片转图纸使用中等卡片（占 ~20% 空间）
  - 两个入口保持明显的视觉层级差异
- **原因**：
  - 吸引注意：大卡片 + 风格标签展示 AI 能力，教育用户
  - 减少步骤：风格前置选择，减少跳转后的操作
  - 商业价值：AI 是付费/增值功能的核心载体
- **影响范围**：CreatorPage、AICreatePage、StyleSelector 组件

---

## 技术决策

### DD-004: 撤销/重做使用差异快照而非完整副本

- **日期**：2026-07-09
- **决策者**：架构师
- **背景**：200×200 网格完整副本需要 1.28MB，50 步撤销栈 = 64MB，浪费内存
- **决策**：
  - 每次操作只快照实际改变的格子（平均 10-200 个）
  - 快照存储格式：`Map<"row,col", oldColorId>`
  - 50 步 × 平均 100 格 × 32 bytes ≈ 160KB
- **原因**：
  - 内存效率：160KB vs 64MB，节省 99.75%
  - 操作速度：序列化少量数据更快
- **影响范围**：EditorState、EditorViewModel.undo/redo

---

### DD-005: 颜色匹配先用欧几里得距离，后升级 CIEDE2000

- **日期**：2026-07-09
- **决策者**：架构师
- **背景**：需要将图片像素映射到有限的拼豆颜色
- **决策**：
  - Phase 1-2 使用 RGB 空间欧几里得距离：`sqrt((r1-r2)²+(g1-g2)²+(b1-b2)²)`
  - Phase 9 可选的 CIEDE2000 升级（感知均匀色彩空间）
- **原因**：
  - 先易后难：欧几里得距离实现简单，拼豆颜色饱和度较高，结果可接受
  - 验证再优化：先用简单算法验证整个流程，再决定是否需要精准匹配
  - CIEDE2000 实现复杂，增加 Phase 1 风险
- **影响范围**：ColorUtils、ColorMappingService

---

### DD-006: AIService 采用 Provider 抽象模式

- **日期**：2026-07-09
- **决策者**：架构师
- **背景**：AI 服务可能使用不同厂商（OpenAI API / 华为盘古 / 本地模型），需要随时切换
- **决策**：
  - 定义 `interface AIProvider` 抽象 AI 调用
  - AIService 通过工厂方法注入具体 Provider
  - 默认实现为空 Provider（返回模拟数据），方便开发调试
- **原因**：
  - 解耦：ViewModel 不依赖具体 AI 服务商
  - 可测试：Mock Provider 无需网络即可开发调试
  - 商业灵活：切换 AI 服务商无需修改 UI 层
- **影响范围**：AIService、AICreateViewModel（Phase 5 实现）

---

### DD-007: Tab 内嵌页面不注册路由、不使用 @Entry

- **日期**：2026-07-09
- **决策者**：架构师
- **背景**：Phase 0 编译错误修复时发现 HomePage/CreatorPage/SquarePage/MinePage 被错误注册为路由页面
- **决策**：
  - Tab 内嵌组件（HomePage/CreatorPage/SquarePage/MinePage）使用 `@Component export struct`
  - 不注册到 main_pages.json
  - 不使用 @Entry（由 MainPage 直接 import 使用）
  - 独立被 router 导航的页面才使用 @Entry + 注册路由
- **原因**：
  - ArkTS 规范：每个路由页面仅有一个 @Entry
  - 避免冲突：Tab 内嵌页面不需要独立路由
- **影响范围**：所有 4 个 Tab 页面、main_pages.json

---

### DD-008: 统一使用 MARD 色号为 V1 唯一标准调色板

- **日期**：2026-07-09
- **修订**：2026-07-09（Artkal → MARD 调整）
- **决策者**：产品经理 + 架构师
- **推翻**：原 3 品牌方案（Hama/Perler/Artkal）
- **背景**：V1 聚焦国内用户，MARD（玛德）是国内主流拼豆品牌。暂不考虑多品牌支持
- **决策**：
  - V1 采用 MARD 官方色号体系作为唯一标准色库
  - 数据模型移除 `brand` 字段，保留扩展能力（未来通过映射层支持其他品牌）
  - 所有模块（AI配色/编辑器/导出）统一使用 MARD 色号
- **原因**：
  - 聚焦 V1 国内用户需求
  - 避免多品牌维护的复杂度
  - 模型可扩展：未来增加品牌时不修改核心数据模型
- **影响范围**：
  - BeadColor.ets — 移除 `brand` 字段
  - ColorPalette.ets — 移除 `brand` 字段
  - Constants.ets — 移除 BRAND_* 常量
  - data/palettes/ — 单文件 StandardPalette.ets（MARD 色号）

---

### DD-009: 颜色匹配升级为 Lab + Delta E 76

- **日期**：2026-07-17
- **决策者**：架构师
- **修订**：DD-005（V1 RGB 距离 → V1 Lab + Delta E 76）
- **背景**：MARD 221 色数据已就绪，RGB 欧几里得距离在人眼感知上不够精准
- **决策**：
  - V1 即采用 CIE76 Delta E（Lab 空间欧几里得距离）进行颜色匹配
  - 算法链：sRGB → 线性化 → XYZ（D65）→ Lab → Delta E 计算
  - 人眼感知阈值 ≈ 2.3，精度满足拼豆场景
  - CIEDE2000 作为 Phase 9 可选升级
- **原因**：
  - Lab 空间更接近人眼对颜色的感知
  - Delta E 76 实现相对简单，221 色遍历 + 实时 Lab 转换 < 2ms/像素
  - 为后续 CIEDE2000 升级预留接口
- **影响范围**：
  - ColorUtils.ets — 新增 rgbToXyz/xyzToLab/rgbToLab/deltaE76
  - ColorMappingService.ets — 匹配逻辑改为 Lab + Delta E 链
  - MardPaletteService.ets — findNearestColor 委托给 ColorMappingService

### DD-010: 图纸预览返回尺寸页时复用原 PixelMap

- **日期**：2026-10-18
- **背景**：图纸生成完成后需要允许用户返回尺寸设置并重新生成；原有流程在生成任务结束时释放 PixelMap，无法安全复用图片预览。
- **决策**：
  - ViewModel 将 PixelMap 临时交给当前生成任务处理。
  - 当前有效任务完成、失败或取消后，将 PixelMap 所有权归还 ViewModel。
  - 预览与尺寸设置在同一导入路由内切换，不复制 PixelMap、不重新解码；重新选图或离开流程时释放。
  - 页面退出导致任务失效时，任务仍负责释放自己持有的 PixelMap，不向失效页面归还。
- **原因**：
  - 保持图片预览与尺寸参数，允许直接修改尺寸后再次生成。
  - 避免保存额外高分辨率图像副本或引入 URI 重解码路径。
  - 明确生成任务与页面状态变更期间的资源所有权。
- **影响范围**：ImageImportViewModel、ImageImportPage、ImportSession 交接生命周期

### DD-011: 当前版本聚焦静态图纸预览与交付

- **背景**：当前版本优先保证普通用户可以完成图片转图纸、查看实际 MARD 色号和材料数量、导出可用图纸。
- **决策**：
  - 当前版本范围包括静态图纸预览、按最终 BeadPattern 计算的材料统计/色号图例，以及独立 PNG 导出。
  - 材料统计与导出共享同一份有效色号统计结果。
  - 完整图纸编辑器、逐格编辑、撤销/重做和编辑手势暂缓；`PATTERN_EDITOR_DESIGN.md` 仅作未来参考。
  - PNG 由图纸数据独立绘制，并由系统文档保存选择器让用户选择保存位置；不截取应用屏幕，也不申请图库写入权限。
- **原因**：让预览、统计与导出能力可独立交付，避免为未计划的编辑器引入状态和手势架构。
- **影响范围**：Phase 3 当前版本计划、ImageImportPage、ImageImportViewModel、图纸统计与 PNG 导出服务。

---

> **日志维护规则**：
> - 每次重大设计变更立即添加新条目
> - 编号递增（DD-XXX）
> - 如推翻旧决策，不删除原记录，标记 `[已推翻: DD-XXX]` 并新建条目
