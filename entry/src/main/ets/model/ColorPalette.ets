/**
 * ColorPalette.ets - 拼豆调色板模型
 *
 * 【职责】
 * 管理一个品牌（如 Hama Midi）的完整拼豆颜色集合。
 * 提供颜色查询功能，是图片转图纸过程中颜色匹配的数据源。
 *
 * 【为什么用数组而非 Map】
 * - 拼豆颜色按色相排序（红→橙→黄→绿→蓝→紫→白→灰→黑），数组天然有序
 * - 单个调色板通常 48-60 个颜色，遍历查找 O(n) 耗时可忽略
 * - 数组序列化简单，未来存储到 RDB 时直接 JSON.stringify
 *
 * 【beadSize 为什么在这】
 * - 同一品牌所有颜色对应同一种珠子尺寸（Midi=5mm, Mini=2.5mm, Maxi=10mm）
 * - 材料计算时需要用 beadSize 估算图纸实际物理尺寸
 *
 * 【数据关系】
 * ColorPalette (1) ──contains──→ (N) BeadColor
 * BeadPattern.paletteId ──ref──→ ColorPalette.id
 *
 * 【数据示例】
 * {
 *   id: 'hama_midi',
 *   name: 'Hama Midi',
 *   brand: 'Hama',
 *   colors: [ BeadColor('白色'), BeadColor('奶白'), ...共48个 ],
 *   beadSize: 5.0,
 *   description: '标准Midi珠子，适合29×29和58×58钉板'
 * }
 */
import { BeadColor } from './BeadColor'

export class ColorPalette {
  /** 调色板唯一标识，如 "hama_midi"、"perler_standard" */
  id: string

  /** 调色板显示名称，如 "Hama Midi"、"Perler Standard" */
  name: string

  /** 品牌名称，如 "Hama"、"Perler"、"Artkal" */
  brand: string

  /**
   * 该品牌的所有颜色列表。
   * 按色相排序（红→橙→黄→绿→蓝→紫），方便 UI 中展示和谐的色带
   */
  colors: BeadColor[]

  /** 珠子直径（毫米）。Midi=5.0, Mini=2.5, Maxi=10.0 */
  beadSize: number

  /** 调色板描述，如适用场景、珠子特点 */
  description: string

  /**
   * 创建一个调色板实例
   *
   * @param id 调色板唯一标识
   * @param name 显示名称
   * @param brand 品牌名称
   * @param colors 颜色列表（按色相排序）
   * @param beadSize 珠子直径（mm）
   * @param description 描述文字
   */
  constructor(
    id: string,
    name: string,
    brand: string,
    colors: BeadColor[],
    beadSize: number,
    description: string
  ) {
    this.id = id
    this.name = name
    this.brand = brand
    this.colors = colors
    this.beadSize = beadSize
    this.description = description
  }

  /**
   * 根据颜色 ID 在调色板中查找颜色
   *
   * @param id 颜色的唯一标识，如 "hama_01"
   * @returns 找到的 BeadColor，未找到返回 undefined
   *
   * 【复杂度】
   * O(n)，n = colors.length（通常 48-60）
   * 对于调色板规模可接受。如需高频调用，Phase 9 可优化为内部 Map 索引
   *
   * 【使用场景】
   * - GridCell.colorId → BeadColor 的转换（Canvas 渲染时需要完整颜色信息）
   * - 材料统计时按颜色分组
   */
  getColorById(id: string): BeadColor | undefined {
    for (let i = 0; i < this.colors.length; i++) {
      if (this.colors[i].id === id) {
        return this.colors[i]
      }
    }
    return undefined
  }

  /**
   * 获取调色板中的颜色总数
   *
   * @returns 颜色数量
   *
   * 【使用场景】
   * - UI 显示"共 N 种颜色"
   * - 验证调色板数据完整性
   */
  getColorCount(): number {
    return this.colors.length
  }
}
