/**
 * BeadColor.ets - 拼豆珠子颜色模型
 *
 * 【职责】
 * 定义一个拼豆品牌的单个颜色。
 * 是调色板（ColorPalette）的最小数据单元，也是颜色匹配算法的目标对象。
 *
 * 【设计决策】
 * - hexColor：UI 显示用（CSS 兼容格式 #RRGGBB）
 * - rgb：算法计算用（ColorUtils 色彩距离计算）
 * - lab：预留 CIEDE2000 精准匹配（Phase 9 前为 [0,0,0]）
 * - name + nameZh：双语支持，name 英文 nameZh 中文
 * - code：品牌原始编码（如 H01, P01），用户购买珠子时的参考编号
 * - brand 冗余存储：避免通过 id 反向查找调色板
 *
 * 【数据示例】
 * {
 *   id: 'hama_01',
 *   brand: 'Hama',
 *   name: 'White',
 *   nameZh: '白色',
 *   code: 'H01',
 *   hexColor: '#FFFFFF',
 *   rgb: [255, 255, 255],
 *   lab: [0, 0, 0]
 * }
 */
export class BeadColor {
  /** 系统唯一标识，格式：{brand}_{序号}，如 "hama_01" */
  id: string

  /** 所属品牌名称，如 "Hama"、"Perler"、"Artkal" */
  brand: string

  /** 颜色英文名称，如 "White"、"Pastel Pink" */
  name: string

  /** 颜色中文名称，如 "白色"、"柔粉" */
  nameZh: string

  /** 品牌内部编码，如 "H01"、"P01"、"A01"。用户购买珠子时参考 */
  code: string

  /** 十六进制颜色值，格式 #RRGGBB，如 "#FF6B6B"。用于 UI 渲染 */
  hexColor: string

  /** RGB 颜色值，三个整数范围 0-255。如 [255, 107, 107]。用于色彩距离计算 */
  rgb: number[]

  /**
   * CIE Lab 颜色值 [L, a, b]。
   * L: 亮度 0-100, a: 绿到红 -128~127, b: 蓝到黄 -128~127
   * Phase 1 预置 [0,0,0]，Phase 9 CIEDE2000 升级时填充实际值
   */
  lab: number[]

  /**
   * 创建一个珠子颜色实例
   *
   * @param id 系统唯一标识
   * @param brand 所属品牌
   * @param name 英文名称
   * @param nameZh 中文名称
   * @param code 品牌编码
   * @param hexColor 十六进制颜色值
   * @param rgb RGB 数组 [R, G, B]
   * @param lab CIE Lab 数组 [L, a, b]，可选，默认 [0,0,0]
   */
  constructor(
    id: string,
    brand: string,
    name: string,
    nameZh: string,
    code: string,
    hexColor: string,
    rgb: number[],
    lab?: number[]
  ) {
    this.id = id
    this.brand = brand
    this.name = name
    this.nameZh = nameZh
    this.code = code
    this.hexColor = hexColor
    this.rgb = rgb
    this.lab = lab !== undefined ? lab : [0, 0, 0]
  }
}
