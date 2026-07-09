/**
 * BeadPattern.ets - 拼豆图纸模型
 *
 * 【职责】
 * 表示一份完整的拼豆图纸。是编辑器操作的核心数据对象，
 * 也是图片转图纸流程的最终产物。
 *
 * 【数据结构】
 * cells[row][col] — row-major 二维数组
 *   cells[0][0] = 左上角第一个格子
 *   cells[gridHeight-1][gridWidth-1] = 右下角最后一个格子
 *
 * 【设计决策】
 * - paletteId 外键引用而非内嵌完整 ColorPalette
 *   原因：一个调色板可被多份图纸共用，内嵌会导致数据冗余
 * - cells 初始化为全空格子（colorId = ''）
 *   原因：用户可能是"先创建空白图纸，后编辑"，而非必须从图片转换
 * - createdAt / updatedAt 使用时间戳（毫秒）
 *   原因：方便排序、筛选、显示相对时间
 *
 * 【数据示例】
 * {
 *   id: 'pattern_001',
 *   name: '小猫图纸',
 *   gridWidth: 29,
 *   gridHeight: 29,
 *   paletteId: 'hama_midi',
 *   cells: [[GridCell(''), GridCell('hama_01'), ...], [...]],
 *   createdAt: 1720512000000,
 *   updatedAt: 1720512000000
 * }
 */
import { GridCell } from './GridCell'

export class BeadPattern {
  /** 图纸唯一标识 */
  id: string

  /** 用户命名的图纸名称，如 "小猫图纸" */
  name: string

  /** 横向格子数（列数）。范围 10-200 */
  gridWidth: number

  /** 纵向格子数（行数）。范围 10-200 */
  gridHeight: number

  /**
   * 关联的调色板 ID（外键引用 ColorPalette.id）。
   * 切换调色板需要重新执行颜色匹配。
   */
  paletteId: string

  /**
   * 二维网格数据 [row][col]。
   * 每个元素为 GridCell，colorId='' 表示空格。
   * 索引范围：row: 0 ~ gridHeight-1, col: 0 ~ gridWidth-1
   */
  cells: GridCell[][]

  /** 图纸创建时间，Unix 毫秒时间戳 */
  createdAt: number

  /** 图纸最后更新时间，Unix 毫秒时间戳 */
  updatedAt: number

  /**
   * 创建一份拼豆图纸
   *
   * @param id 图纸唯一标识
   * @param name 图纸名称
   * @param gridWidth 横向格子数
   * @param gridHeight 纵向格子数
   * @param paletteId 关联调色板 ID
   * @param cells 二维网格数据
   * @param createdAt 创建时间戳
   * @param updatedAt 更新时间戳
   */
  constructor(
    id: string,
    name: string,
    gridWidth: number,
    gridHeight: number,
    paletteId: string,
    cells: GridCell[][],
    createdAt: number,
    updatedAt: number
  ) {
    this.id = id
    this.name = name
    this.gridWidth = gridWidth
    this.gridHeight = gridHeight
    this.paletteId = paletteId
    this.cells = cells
    this.createdAt = createdAt
    this.updatedAt = updatedAt
  }

  /**
   * 创建一个全空的二维网格（所有格子 colorId = ''）
   *
   * 【使用场景】
   * - 新建空白项目时初始化图纸
   * - 重置图纸（清空所有格子）
   *
   * 【复杂度】
   * 时间 O(W×H)，空间 O(W×H)
   * 58×58 = 3,364 个 Cell 创建耗时 < 5ms
   *
   * @param width 横向格子数
   * @param height 纵向格子数
   * @returns 初始化的全空 GridCell 二维数组
   */
  static createEmptyGrid(width: number, height: number): GridCell[][] {
    const cells: GridCell[][] = []
    for (let row = 0; row < height; row++) {
      cells[row] = []
      for (let col = 0; col < width; col++) {
        cells[row][col] = new GridCell() // colorId = '' 空格
      }
    }
    return cells
  }
}
