# PHASE1_DETAILED_DESIGN.md — Phase 1 详细设计评审

> ⚠️ **DD-008 修订（2026-07-09）**：调色板方案已确认。
> V1 采用 MARD（玛德）色号体系作为唯一标准色库。
> 数据模型移除 `brand` 字段。详见 [DESIGN_DECISION_LOG.md §DD-008](./DESIGN_DECISION_LOG.md)

> 本文档在编码前确认所有设计细节、API 选择和开发步骤。
> 确认后严格按此文档实施，不临时变更。

---

## A. 数据模型设计

### A.1 BeadColor（珠子颜色）

```
BeadColor
├── id: string                  // "hama_01"
├── brand: string               // "Hama"
├── name: string                // "White" (英文名)
├── nameZh: string              // "白色" (中文名)
├── code: string                // "H01" (品牌内部编码)
├── hexColor: string            // "#FFFFFF"
├── rgb: [number,number,number] // [255, 255, 255]
└── lab: [number,number,number] // [100.0, 0.0, 0.0] ← Phase 1 暂为 [0,0,0]
```

**设计理由**：

| 决策 | 理由 |
|------|------|
| 同时存 hex 和 rgb | hex 给 UI 显示（CSS兼容），rgb 给算法计算 |
| 预存 Lab 值但在 Phase 1 置零 | 为后续 CIEDE2000 预留字段，避免改模型 |
| name + nameZh 双语 | 为未来多语言预留，Phase 1 只用中文 |
| code 独立于 id | code 是品牌原始编码（用户关心），id 是系统内部标识 |
| 不含 sortIndex | 颜色按色相排序，排序在 Palette 中处理 |

**数据关系**：
```
ColorPalette (1) ──→ (N) BeadColor
  一个调色板包含多个颜色
  BeadColor.brand 冗余存储品牌名（方便直接使用，避免反向查找）
```

---

### A.2 ColorPalette（调色板）

```
ColorPalette
├── id: string                  // "hama_midi"
├── name: string                // "Hama Midi"
├── brand: string               // "Hama"
├── colors: BeadColor[]         // 该品牌所有颜色数组
├── beadSize: number            // 5.0 (mm)
└── description: string         // "适合标准29×29钉板"
```

**设计理由**：

| 决策 | 理由 |
|------|------|
| colors 是数组而非 Map | 需要保持颜色顺序（按色相排列），Map 无序 |
| 冗余 brand 字段 | 快速识别，避免通过 id 解析 |
| beadSize 毫米单位 | 未来材料计算需要区分 Midi/Mini/Maxi |

---

### A.3 GridCell（网格单元格）

```
GridCell
└── colorId: string             // "" = 空位, 其他 = BeadColor.id
```

**设计理由**：

| 决策 | 理由 |
|------|------|
| 只存 colorId 不存完整对象 | 减少内存。100×100=10000个Cell，存string vs object差异大 |
| 空串表示空位 | 简单清晰，比 null 更好序列化 |
| 不存 row/col | 位置由二维数组索引决定，避免数据冗余和不一致 |

---

### A.4 BeadPattern（图纸）

```
BeadPattern
├── id: string
├── name: string                // "我的第一个拼豆"
├── gridWidth: number           // 29
├── gridHeight: number          // 29
├── paletteId: string           // "hama_midi"
├── cells: GridCell[][]         // [row][col]，row-major
├── createdAt: number           // 时间戳(ms)
└── updatedAt: number           // 时间戳(ms)
```

**设计理由**：

| 决策 | 理由 |
|------|------|
| 二维数组 [row][col] | 直观：cells[2][5] = 第3行第6格 |
| cells[0][0] = 左上角 | 屏幕坐标系（y向下），与Canvas绘制一致 |
| paletteId 外键 | 图纸关联调色板，切换调色板需重新匹配颜色 |

**初始化方法**：
```typescript
// 创建空白图纸
static createEmpty(
  id: string,
  name: string,
  width: number,
  height: number,
  paletteId: string
): BeadPattern {
  const cells: GridCell[][] = []
  for (let row = 0; row < height; row++) {
    cells[row] = []
    for (let col = 0; col < width; col++) {
      cells[row][col] = new GridCell()  // colorId = ''
    }
  }
  return { id, name, gridWidth: width, gridHeight: height,
           paletteId, cells, createdAt: Date.now(), updatedAt: Date.now() }
}
```

---

### A.5 Project（项目）

```
Project
├── id: string
├── name: string                // 项目名称（可与图纸名不同）
├── pattern: BeadPattern        // 图纸数据
├── sourceImageUri: string      // 原始图片路径（来源追溯）
├── thumbnailUri: string        // 缩略图路径
├── status: ProjectStatus       // DRAFT | COMPLETED | EXPORTED
├── createdAt: number
└── updatedAt: number
```

**设计理由**：

| 决策 | 理由 |
|------|------|
| Project 包含 BeadPattern | 1:1 关系，一个项目一张图纸 |
| sourceImageUri | 追溯来源，未来支持"重新导入" |
| thumbnailUri | 列表展示用，避免每次渲染完整图纸 |
| status 枚举 | 支持项目筛选和排序 |

---

### A.6 模型关系图

```
Project (1) ──── (1) BeadPattern
                           │
                           │ paletteId (外键)
                           ▼
                     ColorPalette (1)
                           │
                           │ colors[]
                           ▼
                      BeadColor (N)
                           │
                           │ colorId (外键引用)
                           ▼
GridCell[][] ─── 每个Cell.colorId → BeadColor.id
```

---

## B. 页面设计：调色板浏览页

### B.1 页面定位

**PaletteBrowsePage**（调色板浏览）
- 用途：查看系统内置的 3 个品牌调色板
- 入口：Phase 1 暂时从首页快速操作入口进入（临时）；Phase 8 移入设置页
- 不涉及编辑功能（编辑在 Phase 8）

### B.2 用户流程

```
进入调色板浏览
  │
  ├── 看到 3 个品牌卡片（Hama / Perler / Artkal）
  │   每个卡片显示：品牌名 + 颜色数量 + 前5个颜色预览
  │
  └── 点击任一品牌卡片
       └── 进入颜色网格页
           └── 看到该品牌所有颜色
               每个颜色格：色块 + 中文名 + 编码
```

### B.3 ASCII 布局图

**调色板列表页**：

```
┌──────────────────────────────────┐
│  Status Bar                       │
├──────────────────────────────────┤
│  ← 返回    调色板管理             │  ← 顶栏 48vp
├──────────────────────────────────┤
│                                  │
│  ┌────────────────────────────┐  │
│  │  🔴🟠🟡🟢🔵  预览色块      │  │  ← Hama 卡片
│  │                            │  │     圆角 12vp
│  │  Hama Midi                 │  │     阴影 level-1
│  │  48 种颜色 · 5mm珠子      │  │
│  │                    查看 >  │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │  🔴🟠🟡🟢🔵  预览色块      │  │  ← Perler 卡片
│  │  Perler Standard           │  │
│  │  60 种颜色 · 5mm珠子      │  │
│  │                    查看 >  │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │  🔴🟠🟡🟢🔵  预览色块      │  │  ← Artkal 卡片
│  │  Artkal Standard           │  │
│  │  50 种颜色 · 5mm珠子      │  │
│  │                    查看 >  │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

**颜色详情页**（点击品牌后）：

```
┌──────────────────────────────────┐
│  ← 返回    Hama Midi             │  ← 顶栏
├──────────────────────────────────┤
│  共 48 种颜色                    │  ← 计数
├──────────────────────────────────┤
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐     │
│  │  │ │  │ │  │ │  │ │  │     │  ← 颜色网格（Grid）
│  │白│ │奶│ │浅│ │深│ │...│     │     4列，自动换行
│  │色│ │白│ │黄│ │红│ │   │     │     每个格子：
│  │H01│ │H02│ │H03│ │H04│ │   │     │     - 色块 48vp正方形
│  └──┘ └──┘ └──┘ └──┘ └──┘     │     - 中文名 11fp
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐     │     - 编码 11fp
│  │  │ │  │ │  │ │  │ │  │     │
│  └──┘ └──┘ └──┘ └──┘ └──┘     │
│      ↑ 可上下滚动               │
└──────────────────────────────────┘
```

### B.4 组件树

```
PaletteListPage (@Entry)
└── Column (Scroll包裹)
    ├── Text("调色板管理")            ← 页面标题
    └── ForEach → PaletteCard[]
        └── PaletteCard
            ├── Row (前5个颜色预览色块)
            ├── Text(品牌名)
            ├── Text(颜色数量 + 珠子尺寸)
            └── Text("查看 >")

PaletteDetailPage (@Entry)
└── Column
    ├── Text("共 N 种颜色")
    └── Grid (4列)
        └── ForEach → ColorGridItem[]
            └── ColorGridItem
                ├── 色块方块 (48vp × 48vp, 圆角4vp)
                ├── Text(中文名)
                └── Text(编码)
```

### B.5 状态设计

```
PaletteListPage:
  @State palettes: ColorPalette[] = []           ← 3个品牌调色板
  @State selectedBrand: string = ''               ← 暂无使用

  aboutToAppear():
    this.palettes = [
      HamaPalette.getPalette(),
      PerlerPalette.getPalette(),
      ArtkalPalette.getPalette()
    ]

PaletteDetailPage:
  @State palette: ColorPalette                   ← 当前品牌调色板
  @State colors: BeadColor[] = []                ← 该品牌所有颜色

  aboutToAppear():
    从路由参数获取 paletteId
    this.colors = this.palette.colors
```

### B.6 数据流

```
调色板数据文件 (.ets)
  │ HamaPalette.getPalette() → ColorPalette
  │ PerlerPalette.getPalette() → ColorPalette
  │ ArtkalPalette.getPalette() → ColorPalette
  │
  ▼
PaletteListPage
  @State palettes: ColorPalette[]
  │ 用户点击 → router.push(PaletteDetailPage, { paletteId })
  │
  ▼
PaletteDetailPage
  @State colors: BeadColor[]
  │ 渲染 Grid → 用户浏览颜色
```

---

## C. ArkTS API 确认

### C.1 确定可用的 API（已验证）

| API | 用途 | Phase 1 使用位置 |
|-----|------|------------------|
| @Entry / @Component | 页面/组件 | PaletteListPage, PaletteDetailPage |
| @State | 组件状态 | palettes, colors |
| @Builder | UI构建函数 | buildPaletteCard, buildColorItem |
| Column / Row | 布局 | 页面容器 |
| Text | 文字 | 标题/描述/颜色名/编码 |
| Scroll | 滚动 | 颜色网格区域 |
| ForEach | 列表渲染 | 品牌列表/颜色列表 |
| $r('app.color.xxx') | 颜色引用 | 背景/文字色 |
| $r('app.string.xxx') | 字符串引用 | 标题/标签 |
| .borderRadius() | 圆角 | 卡片12vp, 色块4vp |
| .shadow() | 阴影 | 卡片 level-1 |
| router.pushUrl() | 页面跳转 | 列表→详情 |
| interface | 类型定义 | 函数参数类型 |

### C.2 需在编码时验证的 API

| API | 用途 | 风险 | 降级方案 |
|-----|------|------|----------|
| Grid / GridItem | 颜色网格布局 | 低（核心组件） | 改用 Row 手动换行 |
| List / ListItem | 品牌列表 | 低（核心组件） | 改用 Scroll + Column |

*Grid/List 是 ArkUI 核心容器组件，Phase 0 已使用 Tabs/TabContent，同级别 API 应可用。*

### C.3 不使用（已确认不支持）

| API | 替代方案 |
|-----|----------|
| SymbolGlyph (大部分图标) | Text + emoji / Unicode |
| .renderMode() | 删除 |
| 对象字面量类型 `{a: string}` | 显式 interface |

### C.4 状态管理方案

Phase 1 使用最简单的 `@State` 模式：

```typescript
@Component
struct PaletteListPage {
  @State palettes: ColorPalette[] = []

  aboutToAppear(): void {
    // 直接调用调色板数据文件，不经过 Service
    this.palettes = [
      HamaPalette.getPalette(),
      PerlerPalette.getPalette(),
      ArtkalPalette.getPalette()
    ]
  }
}
```

**为什么 Phase 1 不引入 ViewModel？**
- 调色板是只读静态数据，无异步加载、无用户编辑、无复杂状态
- 引入 ViewModel 增加不必要的复杂度
- Phase 2 开始逐步引入 ViewModel

---

## D. Phase 1 开发计划

### 开发顺序

```
Phase 1 (6 个 Step，每步编译验证)
│
├── Step 1: 基础工具和模型文件
│   ├── 新增: utils/ColorUtils.ets
│   ├── 新增: utils/IdGenerator.ets
│   ├── 新增: model/BeadColor.ets
│   ├── 新增: model/ColorPalette.ets
│   ├── 新增: model/GridCell.ets
│   ├── 新增: model/BeadPattern.ets
│   └── 新增: model/Project.ets
│
├── Step 2: 调色板数据
│   ├── 新增: data/palettes/HamaPalette.ets
│   ├── 新增: data/palettes/PerlerPalette.ets
│   └── 新增: data/palettes/ArtkalPalette.ets
│
├── Step 3: ColorMappingService
│   └── 新增: service/ColorMappingService.ets
│
├── Step 4: 调色板列表页
│   ├── 新增: pages/settings/PaletteListPage.ets
│   ├── 修改: main_pages.json (注册新页面)
│   ├── 修改: Constants.ets (添加路由常量)
│   └── 修改: string.json (添加页面标题字符串)
│
├── Step 5: 调色板详情页
│   ├── 新增: pages/settings/PaletteDetailPage.ets
│   └── 修改: main_pages.json (注册新页面)
│
└── Step 6: 集成测试
    ├── 修改: pages/creator/CreatorPage.ets (添加入口按钮)
    └── 验证: 列表→详情完整流程
```

### 各 Step 详细计划

---

#### Step 1: 基础工具和模型文件

**目标**：建立所有数据模型，零编译错误。

**新增文件**：
```
entry/src/main/ets/
├── utils/
│   ├── ColorUtils.ets        ← RGB↔Hex 转换 + 欧几里得距离
│   └── IdGenerator.ets       ← 生成唯一 ID
└── model/
    ├── BeadColor.ets
    ├── ColorPalette.ets
    ├── GridCell.ets
    ├── BeadPattern.ets
    └── Project.ets
```

**ColorUtils 方法清单**：
```typescript
// 全部纯函数，无状态，直接 export function
hexToRgb(hex: string): [number, number, number]
rgbToHex(rgb: [number, number, number]): string
colorDistanceRgb(a: [number,number,number], b: [number,number,number]): number
```

**修改文件**：无（Constants.ets 已有所需常量）

**验证方式**：
```bash
DevEco Studio → Build → Build HAP(s)
确认 CompileArkTS 无错误
```

**预计新增行数**：~200 行

---

#### Step 2: 调色板数据

**目标**：创建 3 个品牌调色板的实际颜色数据。

**新增文件**：
```
data/palettes/
├── HamaPalette.ets      ← 48 色（白/奶白/浅黄/深红/...）
├── PerlerPalette.ets    ← 60 色
└── ArtkalPalette.ets    ← 50 色
```

**数据格式**：每个文件 export 一个工厂函数
```typescript
// HamaPalette.ets
export function createHamaPalette(): ColorPalette {
  const colors: BeadColor[] = [
    { id: 'hama_01', brand: 'Hama', name: 'White', nameZh: '白色',
      code: 'H01', hexColor: '#FFFFFF', rgb: [255,255,255], lab: [0,0,0] },
    // ... 47 个更多颜色
  ]
  return {
    id: 'hama_midi', name: 'Hama Midi', brand: 'Hama',
    colors: colors, beadSize: 5.0,
    description: '标准Midi珠子，适合29×29和58×58钉板'
  }
}
```

**颜色数据来源**：
- Hama 官方色卡 → https://www.hama.com/ (公开的官方颜色列表)
- Perler 官方色卡 → https://www.perler.com/
- Artkal 官方色卡 → https://www.artkalbeads.com/

*数据以官方公布的 RGB/HEX 值为准。无法获取时使用相近颜色替代，并在注释中标注。*

**修改文件**：无

**验证方式**：
```bash
编译 → 确认无错误
# 可在 Index.ets 临时测试：
import { createHamaPalette } from '../data/palettes/HamaPalette'
console.log('Hama colors:', createHamaPalette().colors.length) // 期望 48
```

**预计新增行数**：~350 行（3 个调色板文件，每个 ~100-120 行）

---

#### Step 3: ColorMappingService

**目标**：实现最近邻颜色匹配引擎。

**新增文件**：
```
service/ColorMappingService.ets
```

**方法设计**：
```typescript
export class ColorMappingService {
  private static instance: ColorMappingService | null = null

  static getInstance(): ColorMappingService { ... }

  /**
   * 在调色板中找到与目标RGB最接近的颜色
   * 算法：RGB空间欧几里得距离
   */
  findNearestColor(
    targetRgb: [number, number, number],
    palette: ColorPalette
  ): BeadColor
}
```

**算法复杂度**：
- 每个目标颜色遍历调色板所有颜色
- Hama 48色 = 最多48次距离计算
- 一张 29×29 图纸 = 841 个像素 = 最多 841×48 = 40,368 次计算
- 预期耗时 < 100ms（在 ArkTS 主线程）

**修改文件**：无

**验证方式**：
```bash
编译 → 无错误
# 临时测试代码（Index.ets）：
const service = ColorMappingService.getInstance()
const palette = createHamaPalette()
const result = service.findNearestColor([255, 0, 0], palette)
console.log('Nearest to red:', result.name) // 期望 深红/Red
```

**预计新增行数**：~50 行

---

#### Step 4: 调色板列表页

**目标**：创建 PaletteListPage，展示 3 个品牌卡片。

**新增文件**：
```
pages/settings/PaletteListPage.ets
```

**修改文件**：

| 文件 | 修改 |
|------|------|
| `main_pages.json` | 添加 `"pages/settings/PaletteListPage"` |
| `Constants.ets` | 添加 `ROUTE_PALETTE_LIST` |
| `string.json` | 添加页面标题等字符串 |

**页面结构**：
```
PaletteListPage (@Entry)
├── Column (Scroll)
│   ├── Text("调色板") 标题
│   └── ForEach(palettes) → PaletteCard
│       └── Row
│           ├── Row (前5色预览)
│           ├── Column (名称+数量+尺寸)
│           └── Text("›")
```

**验证方式**：
```bash
编译 → 无错误
# 临时：在 CreatorPage 添加按钮跳转到 PaletteListPage
# 验证页面能正确展示 3 个品牌卡片
```

**预计新增行数**：~120 行

---

#### Step 5: 调色板详情页

**目标**：创建 PaletteDetailPage，展示单个品牌的所有颜色。

**新增文件**：
```
pages/settings/PaletteDetailPage.ets
```

**修改文件**：

| 文件 | 修改 |
|------|------|
| `main_pages.json` | 添加 `"pages/settings/PaletteDetailPage"` |
| `Constants.ets` | 添加 `ROUTE_PALETTE_DETAIL` |

**页面结构**：
```
PaletteDetailPage (@Entry)
├── Column
│   ├── Text("共 N 种颜色")
│   └── Grid (4列)
│       └── ForEach(colors) → ColorItem
│           ├── 色块 (48vp正方形, 圆角4vp)
│           ├── Text(中文名) 11fp
│           └── Text(编码) 11fp
```

**验证方式**：
```bash
编译 → 无错误
# 从 PaletteListPage 点击卡片
# 验证跳转到详情页，颜色网格正确渲染
```

**预计新增行数**：~100 行

---

#### Step 6: 集成测试入口

**目标**：在应用中添加可访问调色板的入口，端到端验证。

**修改文件**：

| 文件 | 修改 |
|------|------|
| `CreatorPage.ets` | 在"AI 风格创作"和"照片转图纸"卡片下方添加"浏览调色板"入口 |
| `string.json` | 添加 `btn_browse_palettes` 字符串 |

**验证方式**：
```bash
编译 → 无错误 → 模拟器运行
操作流程：
  1. 启动 App → 闪屏 → MainPage
  2. 切换到创作Tab
  3. 看到"浏览调色板"入口
  4. 点击 → PaletteListPage（3个品牌）
  5. 点击 Hama → PaletteDetailPage（48色网格）
  6. 返回 → 返回创作页
```

**预计修改行数**：~10 行（仅添加入口按钮）

---

## Phase 1 交付物汇总

| 类型 | 数量 | 文件 |
|------|------|------|
| 新增 Model | 5 | BeadColor, ColorPalette, GridCell, BeadPattern, Project |
| 新增 Utils | 2 | ColorUtils, IdGenerator |
| 新增 Service | 1 | ColorMappingService |
| 新增 数据文件 | 3 | HamaPalette, PerlerPalette, ArtkalPalette |
| 新增 页面 | 2 | PaletteListPage, PaletteDetailPage |
| 修改 配置 | 3 | main_pages.json, Constants.ets, string.json |
| 修改 页面 | 1 | CreatorPage.ets (添加入口) |
| **总计** | **17** | **13 新增 + 4 修改** |

---

> ⏸️ **Phase 1 详细设计评审完成，等待确认后开始编码。**
