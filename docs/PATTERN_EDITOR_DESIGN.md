# PATTERN_EDITOR_DESIGN.md — 图纸编辑器架构设计

> **文件定位**：编辑器核心架构和数据流设计。
> **全局设计系统**：请查阅 [UI_DESIGN.md](./UI_DESIGN.md)
> **页面布局方案**：请查阅 [UI_PHASE0_DESIGN.md](./UI_PHASE0_DESIGN.md)
> **开发阶段**：Phase 4 实现，当前为架构预留设计。

---

## 1. Canvas 数据结构设计

### 1.1 BeadCell（网格单元格）

```typescript
/**
 * BeadCell - 拼豆网格中的单个单元格
 *
 * 【设计决策】
 * - 不存储 row/col 位置信息（位置由它在二维数组中的索引决定）
 * - colorId 是外键引用，避免存储整个 BeadColor 对象
 * - colorId 为空字符串表示空格子
 */
export class BeadCell {
  colorId: string = ''  // 引用 BeadColor.id，空字符串=空位
}
```

**为什么 colorId 是 string 而非 BeadColor 对象？**
1. 减少内存：100×100 网格 = 10000 个 Cell，存储字符串 vs 对象引用差异显著
2. 序列化简单：直接 JSON.stringify 即可
3. 单一数据源：颜色数据在 Palette 中统一管理，避免数据不一致

### 1.2 BeadPattern（图纸）

```typescript
/**
 * BeadPattern - 拼豆图纸，编辑器操作的核心数据结构
 *
 * 【数据组织】
 * cells 是 row-major 二维数组：cells[row][col]
 * cells[0][0] 是左上角，cells[height-1][width-1] 是右下角
 */
export class BeadPattern {
  id: string = ''
  name: string = ''
  gridWidth: number = 29      // 列数 (1~200)
  gridHeight: number = 29     // 行数 (1~200)
  paletteId: string = ''      // 关联的调色板ID
  cells: BeadCell[][] = []    // 二维数组 [row][col]
  createdAt: number = 0
  updatedAt: number = 0
}
```

### 1.3 ColorPalette（调色板）

```typescript
/**
 * ColorPalette - 拼豆调色板
 */
export class ColorPalette {
  id: string = ''
  name: string = ''
  brand: string = ''
  colors: BeadColor[] = []
}

/**
 * BeadColor - 单个珠子颜色
 *
 * 【色彩数据】
 * - hex: 显示用十六进制
 * - rgb: 用于颜色匹配计算（欧几里得距离）
 * - lab: CIE Lab 值（用于精准颜色匹配，可选优化）
 */
export class BeadColor {
  id: string = ''                  // 唯一标识
  brand: string = ''               // 品牌
  name: string = ''                // 颜色名称
  code: string = ''                // 品牌编码，如 "H01"
  hexColor: string = '#000000'     // RGB十六进制
  rgb: [number, number, number] = [0, 0, 0]  // RGB值 0-255
}
```

---

## 2. Canvas 渲染架构

### 2.1 渲染组件结构

```
PatternEditorPage
└── Stack (Canvas容器)
    └── Canvas (ArkUI Canvas组件)
        └── CanvasRenderingContext2D  ← TODO(API_VERIFY)：确认 API 24 中
           │                            CanvasRenderingContext2D 的全量方法
           ├── fillRect(x, y, w, h)    ← 绘制每个颜色格子
           ├── strokeRect(x, y, w, h)  ← 绘制网格线
           ├── fillText(text, x, y)    ← 绘制颜色编号
           └── save()/restore()        ← 管理绘图状态
```

### 2.2 渲染流程

```
每次 render() 调用：
1. context.clearRect(0, 0, canvasWidth, canvasHeight)
2. 根据 zoom 和 pan 计算视口范围
3. 遍历视口内的格子：
   for row in [visibleRowStart..visibleRowEnd]:
     for col in [visibleColStart..visibleColEnd]:
       cell = pattern.cells[row][col]
       if cell.colorId !== '':
         color = palette.getColorById(cell.colorId)
         context.fillStyle = color.hexColor
         context.fillRect(
           (col * cellSize + panX) * zoom,
           (row * cellSize + panY) * zoom,
           cellSize * zoom,
           cellSize * zoom
         )
4. 如果 showGridLines:
   绘制网格线（仅视口内）
5. 如果 showSymbols:
   绘制颜色编号文字（cellSize > 20vp 时才显示）
```

### 2.3 性能计算

```
cellSize = 20vp (默认)
格子数 | 总像素 | 视口可见约 | 每帧fillRect | 预期性能
29×29  | 841    | 841        | 841          | < 8ms (120fps)
58×58  | 3,364  | ~2,000     | ~2,000       | < 16ms (60fps)
100×100| 10,000 | ~2,500     | ~2,500       | < 16ms (60fps)
200×200| 40,000 | ~3,000     | ~3,000       | < 32ms (30fps)

结论：视口裁剪后，200×200 也能维持可用帧率。
     瓶颈不在 draw 调用，而在数据读取。
```

---

## 3. 缩放与平移状态管理

### 3.1 EditorState（运行时状态）

```typescript
/**
 * EditorState - 编辑器运行时状态（不持久化）
 *
 * 【设计决策】
 * 这些状态只在编辑会话中有效，关闭编辑器后丢弃。
 * 项目数据（BeadPattern）独立于编辑状态。
 */
export class EditorState {
  // 视图变换
  zoom: number = 1.0           // 当前缩放比例 (0.25 ~ 4.0)
  panX: number = 0             // 水平平移偏移 (vp)
  panY: number = 0             // 垂直平移偏移 (vp)

  // 工具状态
  activeTool: ToolType = ToolType.PEN   // 当前工具
  selectedColorId: string = ''          // 当前画笔颜色

  // 显示选项
  showGridLines: boolean = true         // 显示网格线
  showSymbols: boolean = false          // 显示颜色编号

  // 撤销/重做
  undoStack: BeadCellSnapshot[] = []    // 撤销栈（最多50步）
  redoStack: BeadCellSnapshot[] = []    // 重做栈
}
```

### 3.2 缩放实现

```
PinchGesture → onActionUpdate
  │
  ├── scale = event.scale
  ├── newZoom = clamp(oldZoom * scale, 0.25, 4.0)
  ├── 以双指中心点为锚点调整 panX/panY
  └── 触发 Canvas 重绘

PanGesture → onActionUpdate
  │
  ├── offsetX = event.offsetX
  ├── offsetY = event.offsetY
  ├── newPanX = oldPanX + offsetX
  ├── newPanY = oldPanY + offsetY
  └── 触发 Canvas 重绘

TODO(API_VERIFY)：确认 PanGesture 和 PinchGesture 的
                  并行处理方式（同时支持单指平移和双指缩放）
```

---

## 4. 撤销/重做数据结构

### 4.1 快照方式

```typescript
/**
 * BeadCellSnapshot - 单步编辑操作的差异快照
 *
 * 【性能优化】
 * 不存储整个网格的副本（200×200 = 40,000 个对象），
 * 只存储本次操作实际改变的格子。
 *
 * 对于 99% 的编辑操作（画笔/橡皮/填充）：
 *   - 画笔：~5-50 个格子
 *   - 填充区域：~10-200 个格子
 *   - 撤销栈内存：50步 × 平均100格 × 约32字节 ≈ 160KB
 */
class BeadCellSnapshot {
  changes: Map<string, string>   // key: "row,col" → value: oldColorId
  toolUsed: ToolType              // 记录使用的工具（用于redo时重放）
}

// 使用示例：
// 用户在 (3,5) 从 "red" 改为 "blue"
// snapshot.changes.set("3,5", "red")  ← 存储旧值
// undo时：把 changes 中的旧值写回对应的 cells[row][col]
```

### 4.2 撤销/重做操作

```
undo():
  if undoStack为空 → 无操作
  snapshot = undoStack.pop()
  redoStack.push(记录当前变化)     ← 先保存当前状态到 redoStack
  for [key, oldColorId] in snapshot.changes:
    [row, col] = key.split(",")
    pattern.cells[row][col].colorId = oldColorId
  触发 Canvas 重绘

redo():
  if redoStack为空 → 无操作
  snapshot = redoStack.pop()
  undoStack.push(记录当前变化)
  for [key, oldColorId] in snapshot.changes:
    [row, col] = key.split(",")
    pattern.cells[row][col].colorId = oldColorId
  触发 Canvas 重绘

新操作（非undo/redo）：
  记录快照 → push到 undoStack
  清空 redoStack               ← 关键：新操作使 redo 失效
  if undoStack.length > 50:
    undoStack.shift()          ← 移除最早的快照
```

---

## 5. 大尺寸图纸性能方案

### 5.1 问题分析

200×200 网格 = 40,000 个格子。同时满足：
- 流畅滚动（60fps）
- 快速响应填充操作（区域可能包含 5000+ 格）
- 撤销栈不会内存溢出

### 5.2 渲染优化

| 技术 | 说明 |
|------|------|
| 视口裁剪（Viewport Culling） | 只渲染屏幕上可见的格子 |
| requestAnimationFrame 合并 | 多个连续更新合并为一次重绘 |
| Canvas 而非 DOM 组件 | 一次 Canvas draw 替代 40,000 个 Component |
| 脏矩形（Dirty Rect） | 仅重绘发生变化的区域（Phase 9 优化） |

### 5.3 填充算法优化

```
Flood Fill（泛洪填充）：
  起点格子 → BFS/DFS 查找相邻同色格
  最坏情况：整个网格同色 = 40,000 格

  优化方案：
  1. 使用 BFS + 队列（非递归，避免栈溢出）
  2. 对于 > 1000 格的大区域，分批处理：
     - 每 16ms 处理一批（保持 60fps）
     - 显示进度（"正在填充..."）
  3. 使用 Uint8Array 位图加速相邻检查
```

### 5.4 内存预算

```
200×200 网格内存估算：
  BeadCell 对象：40,000 × ~32 bytes ≈ 1.28 MB
  Canvas 绘制上下文：≈ 2-4 MB
  调色板（180色）：≈ 50 KB
  撤销栈（50步 × 200变化）：≈ 320 KB
  ─────────────────────────────
  总计：≈ 5 MB

内存目标 < 200 MB → 编辑器占用 < 10 MB ✅
```

---

## 6. API 不确定性标记

> 以下 API 在编码前需要查阅官方文档确认。不允许猜测。

| API | 用途 | 状态 | 确认方式 |
|-----|------|------|----------|
| CanvasRenderingContext2D | 编辑器核心渲染 | TODO(API_VERIFY) | 查阅 API Reference → Canvas |
| PanGesture + PinchGesture 并行 | 缩放+平移手势 | TODO(API_VERIFY) | 查阅 ArkUI 手势指南 |
| bindSheet() | 材料统计底部面板 | TODO(API_VERIFY) | 查阅 API Reference → bindSheet |
| CustomDialogController | 确认对话框 | TODO(API_VERIFY) | 查阅 API Reference → 对话框 |
| router.pushUrl 嵌套路由 | 编辑器内子页面 | ✅ 已验证（Phase 0 编译通过） |
| @Observed + @ObjectLink | 状态管理 | ✅ 已验证（官方文档确认） |
| SymbolGlyph 图标列表 | 获取完整支持列表 | TODO(API_VERIFY) | 查阅 API Reference → SymbolGlyph |

### 降级方案

如果 `bindSheet()` 不可用：
→ 使用 `Stack` + `translate` 动画手动实现 Bottom Sheet

如果 PanGesture 和 PinchGesture 不能并行：
→ 使用单一 GestureGroup 按优先级处理

---

## 7. 编辑器的 ViewModel → Service 数据流

```
EditorViewModel (管理 UI 状态)
  │
  ├── EditorState (运行时状态：zoom/pan/tool/undo)
  │
  ├── 用户操作 → 方法调用                          │
  │   ├── onCellTap(row, col)                     │
  │   ├── onCellLongPress(row, col)               │
  │   ├── onPinch(scale, centerX, centerY)        │
  │   ├── onPan(offsetX, offsetY)                 │
  │   ├── undo() / redo()                         │
  │   └── changeTool(tool: ToolType)              │
  │                                                │
  └── 调用 Service 层                              │
      ├── ColorMappingService.findColor(hex)       │
      ├── ExportService.exportPng(pattern, palette)│
      └── MaterialCalculationService.count(pattern)│
```

---

> 此文档为 Phase 4 编辑器开发的架构依据。
> 在 Phase 4 开始编码前，需先解决所有 TODO(API_VERIFY) 标记。
