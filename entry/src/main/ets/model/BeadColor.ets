/**
 * BeadColor.ets - 拼豆珠子颜色模型
 *
 * 【职责】
 * 定义一个拼豆颜色。是调色板（ColorPalette）的最小数据单元。
 *
 * 【设计决策 — DD-008】
 * V1 采用 MARD（玛德）色号体系作为唯一标准。
 * id 直接使用 MARD 原始色号（如 "H18", "A1", "C2"），不再单独设 code 字段。
 * 不设 brand 字段，未来通过映射层扩展其他品牌。
 *
 * 【数据示例】
 * {
 *   id: 'H18',
 *   name: 'White',
 *   nameZh: '白色',
 *   hexColor: '#FFFFFF',
 *   rgb: [255, 255, 255],
 *   lab: [0, 0, 0]
 * }
 */
export class BeadColor {
  /**
   * 颜色唯一标识 = MARD 原始色号。
   * 示例："H18", "A1", "B17", "C2"
   * 是整个项目中的颜色唯一引用键。
   */
  id: string

  /** 颜色英文名称，如 "White", "Pastel Pink" */
  name: string

  /** 颜色中文名称，如 "白色", "柔粉" */
  nameZh: string

  /** 十六进制颜色值，格式 #RRGGBB，如 "#FF6B6B"。用于 UI 渲染 */
  hexColor: string

  /** RGB 颜色值 [R, G, B]，范围 0-255。用于色彩距离计算 */
  rgb: number[]

  /** CIE Lab 颜色值 [L, a, b]，由调色板服务初始化时计算并缓存 */
  lab: number[]

  /**
   * 创建一个珠子颜色实例
   *
   * @param id MARD 原始色号（如 "H18"）
   * @param name 英文名称
   * @param nameZh 中文名称
   * @param hexColor 十六进制颜色值
   * @param rgb RGB 数组 [R, G, B]
   * @param lab CIE Lab 数组 [L, a, b]，可选，默认 [0,0,0]
   */
  constructor(
    id: string,
    name: string,
    nameZh: string,
    hexColor: string,
    rgb: number[],
    lab?: number[]
  ) {
    this.id = id
    this.name = name
    this.nameZh = nameZh
    this.hexColor = hexColor
    this.rgb = rgb
    this.lab = lab !== undefined ? lab : [0, 0, 0]
  }
}
