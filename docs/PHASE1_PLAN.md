# PHASE1_PLAN.md — Phase 1 开发计划

> **Phase 1 目标**：完成数据层基础 — 数据模型 + 调色板 + 颜色匹配引擎

---

## 1. 新增文件列表

```
entry/src/main/ets/
├── model/
│   ├── BeadColor.ets           ← 珠子颜色（id/name/hex/rgb/lab）
│   ├── ColorPalette.ets        ← 调色板（brand + colors[]）
│   ├── GridCell.ets            ← 网格单元格（colorId引用）
│   ├── BeadPattern.ets         ← 图纸（二维数组 + 元数据）
│   └── Project.ets             ← 项目（图纸 + 来源 + 状态）
│
├── data/palettes/
│   ├── HamaPalette.ets         ← Hama Midi 48色
│   ├── PerlerPalette.ets       ← Perler Standard 60色
│   └── ArtkalPalette.ets       ← Artkal Standard 50色
│
├── utils/
│   ├── ColorUtils.ets          ← Hex↔RGB↔Lab 转换 + 色彩距离
│   └── IdGenerator.ets         ← UUID/时间戳 ID 生成器
│
└── service/
    └── ColorMappingService.ets ← 最近邻颜色匹配（单例）
```

**共 10 个新文件**

---

## 2. 修改文件列表

| 文件 | 修改内容 |
|------|----------|
| `utils/Constants.ets` | 补充颜色相关常量（如有缺失） |
| `docs/CHANGELOG.md` | Phase 1 完成记录 |
| `docs/TODO.md` | 标记 Phase 1 任务完成 |

**共 3 个修改文件**

---

## 3. 数据模型设计

### 3.1 BeadColor

```typescript
export class BeadColor {
  id: string            // "hama_01"
  brand: string         // "Hama"
  name: string          // "White"
  code: string          // "H01"
  hexColor: string      // "#FFFFFF"
  rgb: [number,number,number]  // [255,255,255]
  lab: [number,number,number]  // [100,0,0] ← 由 ColorUtils 计算
}
```

### 3.2 ColorPalette

```typescript
export class ColorPalette {
  id: string            // "hama_midi"
  name: string          // "Hama Midi"
  brand: string         // "Hama"
  colors: BeadColor[]   // 48个颜色
  beadSize: number      // 5.0 (mm)
}
```

### 3.3 GridCell

```typescript
export class GridCell {
  colorId: string       // 引用 BeadColor.id，空字符串=空位
}
```

### 3.4 BeadPattern

```typescript
export class BeadPattern {
  id: string
  name: string
  gridWidth: number     // 列数
  gridHeight: number    // 行数
  paletteId: string
  cells: GridCell[][]   // [row][col]
  createdAt: number
  updatedAt: number
}
```

### 3.5 Project

```typescript
export enum ProjectStatus { DRAFT, COMPLETED, EXPORTED }

export class Project {
  id: string
  name: string
  pattern: BeadPattern
  sourceImageUri: string   // 原始图片路径（图片导入来源）
  thumbnailUri: string     // 缩略图路径
  status: ProjectStatus
  createdAt: number
  updatedAt: number
}
```

---

## 4. Service 设计

### 4.1 ColorMappingService

```typescript
export class ColorMappingService {
  static getInstance(): ColorMappingService

  /**
   * 在调色板中找到与目标颜色最接近的珠子颜色
   * @param targetRgb 目标RGB值
   * @param palette 要搜索的调色板
   * @returns 最接近的 BeadColor，或 null（调色板为空）
   *
   * 算法：欧几里得距离（RGB空间）
   * distance = sqrt((r1-r2)² + (g1-g2)² + (b1-b2)²)
   * 选择距离最小的颜色
   */
  findNearestColor(targetRgb: [number,number,number],
                   palette: ColorPalette): BeadColor | null

  /**
   * 批量匹配（一次性匹配多个颜色，优化循环）
   */
  findNearestColors(targetRgbs: [number,number,number][],
                    palette: ColorPalette): (BeadColor | null)[]
}
```

**为什么用欧几里得距离而不是 CIEDE2000？**
- 欧几里得距离实现简单，计算快速
- 拼豆颜色饱和度较高，RGB距离已能较好区分
- CIEDE2000 作为 Phase 9 优化项

---

## 5. ViewModel 设计

**Phase 1 暂不创建 ViewModel**。

Phase 1 只建数据层（Model + Utils + Service），ViewModel 在各自 Phase 中创建：
- CreatorViewModel → Phase 2
- EditorViewModel → Phase 4
- 等等

---

## 6. 页面影响范围

**Phase 1 不修改任何页面 UI**。

数据模型创建后，可以通过以下方式验证：
1. 在 Index.ets 的 aboutToAppear 中写临时测试代码
2. 创建 Palette 实例 → 调用 ColorMappingService → 打印结果
3. 验证完成后删除测试代码

---

## 7. 编译验证方案

```
Step 1: 创建所有数据模型文件 → 编译 → 确认无类型错误
Step 2: 创建颜色工具类 → 编译 → 确认无导入错误
Step 3: 创建 3 个调色板数据 → 编译 → 确认数据格式正确
Step 4: 创建 ColorMappingService → 编译 → 确认 Service 模式正确
Step 5: 在 Index.ets 中临时测试匹配算法 → 运行 → 验证算法正确性
Step 6: 删除测试代码 → 编译 → 最终验证
```

每步编译通过后再进行下一步。

---

## 8. Phase 1 验收标准

- [ ] 5 个数据模型正确创建
- [ ] 3 个品牌调色板包含完整颜色数据（158+ 色）
- [ ] ColorUtils 颜色转换和距离计算正确
- [ ] ColorMappingService 匹配准确率 > 90%（人工抽样测试）
- [ ] 所有文件编译通过
- [ ] 无硬编码颜色值（全部通过调色板数据管理）
- [ ] CHANGELOG.md 和 TODO.md 已更新

---

> ⏸️ 此计划确认后开始 ArkTS 编码。
