# ROADMAP.md — 开发路线图

## Phase 0: 项目初始化与 4Tab 导航框架 ✅

**目标**：搭建项目基础架构，实现底部 4Tab 导航
**状态**：已完成

**输出**：
- 项目目录结构创建
- 颜色/字符串资源（浅色+深色）
- 全局常量 Constants.ets
- Index.ets 闪屏页（1.5s 动画→跳转）
- MainPage.ets 4Tab 容器
- 4 个 Tab 占位页面 + 8 个子页占位
- main_pages.json 路由注册

---

## Phase 1: 数据模型与调色板系统

**目标**：完成数据层基础

**计划**：
- 10 个数据模型（BeadColor, ColorPalette, GridCell, BeadPattern, Project, Work, Comment, UserProfile, AppSettings, EditorState）
- 3 个品牌调色板（Hama 48色, Perler 60色, Artkal 50色）
- ColorUtils（RGB↔Hex↔Lab，色彩距离）
- ColorMappingService（最近邻匹配引擎）
- ColorPaletteBar + ColorChip UI 组件
- PreferencesHelper 基础读写

---

## Phase 2: 图片导入功能

**目标**：实现相册选图和预览

**计划**：
- photoAccessHelper 相册选择
- 图片加载和基本信息展示
- 导入参数配置界面（网格尺寸、调色板选择）
- ImageImportPage 完整实现

---

## Phase 3: 拼豆图纸生成（核心）

**目标**：图片→像素化→颜色映射→图纸

**计划**：
- ImageProcessingService（缩放/像素化/采样）
- ImageImportViewModel（完整转换流水线）
- BeadGrid 组件（Canvas 绘制网格）
- 转换进度条
- 预览确认→保存流程

---

## 当前版本完善：图纸信息与 PNG 导出

**目标**：完成图片转图纸的预览交付，不依赖完整图纸编辑器。

**计划**：
- 根据最终 BeadPattern 统计实际有效 MARD 色号和颗数
- 在可滚动预览页显示实际色号图例、每色数量和总颗数
- 生成独立 PNG：网格、尺寸、行列编号、实际用色图例和数量
- 通过系统文档保存选择器让用户选择导出位置
- API 24 HAP 构建、数据一致性检查及设备导出验证

## 暂缓：完整图纸编辑器（原 Phase 4）

完整编辑器移出当前版本范围，设计文档仅作为未来参考：
- EditorViewModel、PatternEditorPage、ToolBar
- 逐格绘制/擦除/填充/吸色、撤销重做
- 双指缩放、平移和编辑手势

材料统计和 PNG 导出是当前图纸预览交付能力，不依赖编辑器。

---

## Phase 5: AI 图片创作

**目标**：AI 风格化图片创作

**计划**：
- AIService（Provider 抽象，可切换后端）
- AICreateViewModel（风格化→转图纸流程）
- AICreatePage（图片上传 + 风格选择器 + 结果预览）
- 生成进度 + 错误处理

---

## Phase 6: 项目管理与本地存储

**目标**：项目持久化存储和列表管理

**计划**：
- StorageService（RDB + Preferences 完整实现）
- HomeViewModel（项目列表/搜索/排序）
- HomePage 完整实现
- ProjectCard / EmptyState / ConfirmDialog 组件
- 启动流程完善

---

## Phase 7: 广场社区

**目标**：完整的社区功能

**计划**：
- CommunityService（后端 API 封装）
- SquareViewModel（分页/刷新/搜索/标签过滤）
- SquarePage（瀑布流布局）
- WorkDetailPage（大图 + 评论 + 点赞收藏）
- CommentItem + WorkCard 组件
- UserProfilePage（用户主页）
- 发布作品功能
- 推荐机制

---

## Phase 8: 个人中心与设置

**目标**：个人中心和全局设置

**计划**：
- MinePage 完整实现
- MyWorksPage / MyFavoritesPage
- SettingsPage（默认参数/主题/语言/关于）
- 自定义调色板

---

## Phase 9: 打磨与发布优化

**目标**：应用商店发布准备

**计划**：
- 全局动画优化
- 性能优化（Canvas 视口裁剪/懒加载）
- 错误边界 + 全局异常处理
- 网络状态监听 + 离线降级
- 无障碍适配
- 隐私政策 + 用户协议
- AppGallery 发布准备
