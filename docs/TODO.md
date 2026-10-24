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
- [x] DevEco 模拟器交互验证（2026-10-24 用户确认完成；真机验证因无真机挂起）

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
- [x] 验证图库保存取消、重名处理（2026-10-24 模拟器 A/B 验证通过：取消有提示不崩溃、图库不新增；连续保存文件名唯一且均可打开）；透明空格在 V1 白底合成流程下无法从 UI 触发，挂起至编辑器阶段
- [x] API 24 模拟器验证 29→58→87→200 重生成、返回保留原图、取消恢复设置、重新选图后生成
- [x] 模拟器验证 116×116 图纸总数为 13,456；PNG 保存为 `BeadPattern_116x116.png`，系统识别为 `image/png` 并成功解码/打开（1240×1874）
- [x] 线条图模式（2026-10-24，经五轮迭代后冻结）：导入页新增「图纸风格」切换——照片（区域平均，过渡自然）/ 线条图（众数量化桶采样 + 暗线优先（亮度<35、占比≥10%）+ 自动裁白边 + 宽高比适配居中留白 + 色彩精简前 6 主色）。裁白边与宽高比适配同时作用于照片模式
- [x] 成品尺寸厘米提示（按 5mm 拼豆 1 格 = 0.5cm）：预设按钮下方 ≈X cm 小字 + 动态「成品约 X × Y cm」行（覆盖预设/推荐/自定义尺寸）
- 说明：29×29 小尺寸残留细节问题（五官大小眼、粗边、胡须连脸、小色块丢失）为逐格采样量化极限，自动算法已到顶，由图纸编辑器手动修格解决；58×58 及以上效果良好
- [x] 模拟器逐色核对统计与图格一致，并检查 PNG 图例、编号和图纸视觉内容（2026-10-24 通过：总数硬校验、图例/编号/网格线核对、抽样数格与换尺寸抽查均符合预期）
- [ ] 真机复测颜色还原、统计/导出、静态预览性能、取消和 PixelMap 资源释放（用户暂无真机，挂起）
- [x] `SDK component missing` 构建问题已解决（2026-10-24 用户确认：近期多轮 Build HAPs 正常出包、模拟器运行正常，环境层已通，无需修复）

## 增强：图片剪裁（轻量版）— ✅ 已完成（2026-10-24）

- [x] API 查证：`PixelMap.crop(region)` 已核对并记入 `docs/REFERENCES.md`（API 12+；因就地修改改用采样偏移方案，另核对 `writePixels` 用于剪裁预览副本）
- [x] 剪裁数据流：CropRect（x/y/width/height 源图像素坐标）→ ImageImportData → ImageProcessingService 采样偏移（钳制边界；内容框扫描/宽高比适配/采样均限定在剪裁区域内，三种风格通用）
- [x] 剪裁 UI：同页覆盖层编辑器（ViewModel 为页面私有实例，弃用独立页方案）+ 比例预设（自由/1:1/4:3/3:4）+ 框内拖动移动 + 四角手柄缩放；入口按钮固定于可视图片区域右下角（不随滚动）
- [x] 坐标换算：显示坐标 ↔ 原图像素按 Contain 缩放换算 + 边界钳制（最小 16px）；已修复 findContentBounds 缓冲区相对列号 bug（剪裁后"只剩半张脸"）
- [x] 状态保留：重新选图 / 全量重置时自动清空剪裁并释放预览副本；剪裁后预览图替换为剪裁结果（框选整图视为未剪裁）
- [x] 编译验证 + 模拟器交互验证（2026-10-24 用户确认通过）

## 增强：透明度支持 → 背景→空格（含泛洪去白底）— ✅ 已完成（2026-10-24）

- [x] 导入参数「背景处理」开关：白底 · 默认（现行为）/ 空格 · 异形（默认白底，保持现有行为）；两种图片（有无透明通道）均可用
- [x] ImageProcessingService 透明路径：alpha ≤ 127 占比过半 → 空格（colorId=''）；alpha > 127 维持白底合成
- [x] 泛洪去白底：白底图（含带 alpha 通道但背景不透明的 PNG）从剪裁区四边泛洪标记连通白色背景——阈值 200 + 掩码向相邻浅色像素（三通道≥180）扩张 2 轮吃掉模糊过渡带，深色轮廓挡住扩张、图内白色不受影响
- [x] 判定顺序：线条图模式暗线判定先于空格判定（带暗线的格子黑线优先于挖空，保住胡须等细线）；留白行/列（宽高比适配填充区）在异形模式下同样留空
- [x] 全空图生成失败的用户可见错误提示（"图片内容几乎全部为背景"）
- [x] BeadGrid 静态预览空格渲染：#EFEFEF 浅灰底
- [x] PNG 导出空格渲染：浅灰底（EMPTY_CELL_FILL_COLOR），与 H1 白豆可区分；统计口径不含空格
- [x] 编译验证 + 模拟器验证（2026-10-24 用户验收通过：Kitty 白底图背景挖空、黑圈消除、上下留白变空格、胡须保持细线）
- 说明：服务异形拼豆场景（挂件/钥匙扣）；泛洪/扩张阈值（200/180）为经验值，遇特殊图可再调

## 增强：PNG 格内色号标注 — 排期：透明度之后

- [ ] 格子像素自适应：按色号字符数与网格尺寸计算（约 24~32px，大图取下限控制画布尺寸）
- [ ] 每格色号文本绘制：复用 Font 对象；同色 run 合并仅用于色块，文字逐格绘制
- [ ] 文字明暗自适应：按每色 RGB 亮度选择白字/深字（复用 ColorUtils）
- [ ] 小格子退回规则：格子像素 < 16px 时不做格内标注，仅保留图例
- [ ] 导出开关「格内标注色号」
- [ ] 编译验证 + PNG 视觉验收（5 倍放大可读性）
- 说明：仅改 PatternExportService 绘制层，不触碰采样/统计链路，无需重跑逐色核对回归

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
