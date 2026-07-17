/**
 * ColorPalette.ets - 拼豆调色板模型
 *
 * 【职责】
 * 管理拼豆颜色集合。是图片转图纸过程中颜色匹配的数据源。
 *
 * 【设计决策 — DD-008】
 * V1 不设 brand 字段。调色板通过 id/name 区分。
 * 所有模块统一使用 MARD 色号体系。
 *
 * 【数据示例】
 * {
 *   id: 'mard_standard',
 *   name: 'MARD 标准色',
 *   colors: [ BeadColor('白色'), BeadColor('奶白'), ... ],
 *   beadSize: 5.0,
 *   description: 'MARD 5mm 标准融合豆色卡'
 * }
 */
import { BeadColor } from './BeadColor'

export class ColorPalette {
  /** 调色板唯一标识，如 "mard_standard" */
  id: string

  /** 调色板显示名称，如 "MARD 标准色" */
  name: string

  /**
   * 颜色列表。
   * 按色号顺序排列，方便 UI 中展示
   */
  colors: BeadColor[]

  /** 珠子直径（毫米）。标准融合豆 = 5.0 */
  beadSize: number

  /** 调色板描述 */
  description: string

  constructor(
    id: string,
    name: string,
    colors: BeadColor[],
    beadSize: number,
    description: string
  ) {
    this.id = id
    this.name = name
    this.colors = colors
    this.beadSize = beadSize
    this.description = description
  }

  /**
   * 根据色号在调色板中查找颜色
   * @param id MARD 色号，如 "H18"
   * @returns 找到的 BeadColor，未找到返回 undefined
   */
  getColorById(id: string): BeadColor | undefined {
    for (let i = 0; i < this.colors.length; i++) {
      if (this.colors[i].id === id) {
        return this.colors[i]
      }
    }
    return undefined
  }

  /** 获取颜色总数 */
  getColorCount(): number {
    return this.colors.length
  }
}
