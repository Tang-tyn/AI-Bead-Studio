# PROJECT_STATUS.md — 项目状态总览

> 最后更新：2026-10-18
> 当前阶段：Phase 3 拼豆图纸生成（核心）进行中

---

## 一、总体进度

```
Phase 0:   项目初始化与4Tab导航框架     ✅ 100%
Phase 0.5: UI设计系统 + 文档体系建设    ✅ 100%
Phase 1:   数据模型与调色板系统         ✅ 100%  (6/6 Steps)
Phase 2:   图片导入功能                 🟡 代码已完成，待模拟器/真机交互验证
Phase 3:   拼豆图纸生成（核心）         🟡 代码已完成；模拟器已验证统计总数与 PNG 保存/打开，逐色核对及真机验证待完成
Phase 4:   完整图纸编辑器               ⏸️ 暂缓，不属于当前版本范围
Phase 5:   AI图片创作                   🔴 未开始
Phase 6:   项目管理与本地存储           🔴 未开始
Phase 7:   广场社区                     🔴 未开始
Phase 8:   个人中心与设置               🔴 未开始
Phase 9:   打磨与发布优化               🔴 未开始
```

---

## 二、Phase 1 完成报告

### Step 1: Model 数据层 ✅
| 文件 | 行数 | 职责 |
|------|------|------|
| BeadColor.ets | 73 | 拼豆颜色（id=色号, hexColor, rgb, lab） |
| ColorPalette.ets | 73 | 调色板（colors[], getColorById, getColorCount） |
| GridCell.ets | 41 | 网格单元格（极简：仅 colorId） |
| BeadPattern.ets | 124 | 拼豆图纸（cells[row][col] + createEmptyGrid） |
| Project.ets | 113 | 项目包装（pattern + 来源 + ProjectStatus 枚举） |

### Step 2: MARD 调色板数据 ✅
| 文件 | 说明 |
|------|------|
| MardPalette.ets | JSON 加载器：rawfile → BeadColor[] |
| MardPalette.json (rawfile) | 221 色完整数据（37KB） |

### Step 3: ColorUtils ✅
| 文件 | 行数 | 能力 |
|------|------|------|
| ColorUtils.ets | 151 | hex↔rgb, rgb→XYZ→Lab, Delta E 76 |

### Step 4: ColorMappingService ✅
| 文件 | 行数 | 能力 |
|------|------|------|
| ColorMappingService.ets | 77 | Lab + Delta E 最近邻匹配引擎 |
| MardPaletteService.ets | 93 | MARD 221 色数据服务（查询/初始化） |

### Step 5: 测试页面 ✅
| 文件 | 行数 | 能力 |
|------|------|------|
| PaletteTestViewModel.ets | 98 | 测试页状态管理 |
| PaletteTestPage.ets | 308 | 221色网格 + 匹配测试 |

### Step 6: 编译验证 ✅
- JSON 正常读取
- 221 色 Grid 正常渲染
- Lab + Delta E 匹配正常

### Phase 1 累计
```
Model/       5 文件   424行
Data/        1 文件    73行
Utils/       1 文件   151行
Service/     2 文件   170行
ViewModel/   1 文件    98行
Pages(test)/ 1 文件   308行
配置          3 文件   +3行
rawfile      1 文件   37KB
          ───────  ─────
总计        14 文件  1227行
```

---

## 三、设计决策记录

| 编号 | 内容 |
|------|------|
| DD-001 | HomePage ≠ 创作入口 |
| DD-002 | Canvas 渲染优化 |
| DD-003 | AI 大卡片设计 |
| DD-004 | 差异快照撤销 |
| DD-005 | V1 先 RGB 距离 → V1 Lab+DeltaE（DD-009 修订） |
| DD-006 | AI Provider 抽象 |
| DD-007 | Tab 页面不注册路由 |
| DD-008 | V1 MARD 唯一品牌标准 |
| DD-009 | Lab + Delta E 76 精准匹配 |

---

## 四、当前版本交付与验证状态

- 当前范围：选择图片 → 设置尺寸 → 生成 MARD 221 色图纸 → 静态预览 → 实际用色及材料统计 → PNG 导出。
- 统计数据由最终图纸逐格计算；PNG 为独立离屏绘制，包含尺寸、行列编号、色号图例及颗数，不是屏幕截图。
- 曾有 API 24 HAP 构建成功记录；本次画笔绑定修复后的构建未能完成，Hvigor 报错 `SDK component missing`，见下方环境问题记录。
- API 24 模拟器已验证：29×29 → 58×58 → 87×87 → 自定义 200×200 连续生成；返回尺寸页原图与尺寸保留；200×200 取消后原图和参数可继续使用；重新选图后旧结果清除并可生成新图。
- API 24 模拟器本次验证：生成 116×116 图纸，页面显示总数 13,456、60 种颜色；导出文件名为 `BeadPattern_116x116.png`，系统文件预览识别为 `image/png`、30564 字节、1240×1874，并成功解码打开。
- PNG 图纸导出已由用户人工验收：图片成功保存到图库，图片颜色和内容显示正常。此项为人工运行验收，不代表本次完成了 HAP 构建或真机验证。
- PNG 默认保存方式使用 `PhotoAccessHelper.showAssetsCreationDialog()` 系统图库确认流程；确认后还需向返回的图库 URI 写入 PNG 数据。文件保存选择器保留为「保存到指定位置」选项。
- 尚待模拟器验证：各色数量与图格逐一核对、不同尺寸下统计变化、保存取消/重名处理及透明空格。PNG 图纸的图库保存、颜色和内容已由用户人工确认；此前文件预览验证过 PNG 可解码打开。
- 尚待真机验证：图片颜色还原、静态预览性能、取消期间任务隔离及 PixelMap 释放。

### 本次构建环境问题

- 本次尝试执行 API 24 HAP 构建失败，Hvigor 报错 `SDK component missing`。
- SDK 根目录的 `sdk-pkg.json` 标示 HarmonyOS 6.1.1 / API 24，但 Hvigor 未能从当前 SDK 安装中解析所需组件；分别将 `DEVECO_SDK_HOME` 指向 SDK 根目录和 `hms` 子目录后仍得到相同错误。
- 该问题目前定位为 SDK 组件发现/安装配置问题，尚未进一步确定具体缺失组件；不属于业务代码问题。本次不调整业务代码，也不把本次修改记为构建通过。
- 后续处理：在 DevEco Studio 的 SDK Manager 检查并修复 HarmonyOS 6.1.1 / API 24 所需组件及组件注册，再重试 HAP 构建。

## 五、下一步

**Phase 2 / Phase 3 设备验证**
- DevEco 模拟器验证色号统计和 PNG 导出边界场景（取消、重名、透明空格）
- DevEco 模拟器/真机验证相册选择、预览、尺寸预设与取消/错误流程
- 验证生成成功、失败、取消时 PixelMap 释放和导入数据交接
- 检查并修复 Hvigor 的 `SDK component missing` 环境问题，再完成当前代码的 API 24 HAP 构建
- 验证 10×10、58×58、200×200 静态预览的方向、颜色、缩放和绘制性能
- 确认每格边界细线及每 5 格粗分隔线在不同网格尺寸下的对齐和可读性
- 验证页面离开/重入后预览状态清除，以及无效色值的安全留空显示
- 验证设备运行中 MARD 初始化和转换进度反馈
- 复测 PixelMap RGBA_8888 `readPixels()` 的 BGRA 通道修正对真实图片颜色的还原效果
- 真机验证重复触发、重新选图和退出页面期间 PixelMap 释放与任务隔离
- 本次 HAP 编译验证不代替模拟器/真机运行验证

**当前版本范围外**
- 暂缓完整图纸编辑器；设计参考保留，但不搭建编辑器架构
