/**
 * MardPaletteService.ets - MARD 221 色调色板数据服务
 *
 * 【职责】
 * 管理 V1 唯一标准色库（MARD 221色）。
 * 提供颜色查询功能。颜色匹配由 ColorMappingService 负责。
 *
 * 【DD-008】
 * V1 默认颜色体系：MARD 221 色。不区分品牌。
 *
 * 【架构】
 * 单例模式。接收已解析的 BeadColor[] 数据进行初始化。
 */
import { BeadColor } from '../model/BeadColor'
import { ColorPalette } from '../model/ColorPalette'

export class MardPaletteService {
  private static instance: MardPaletteService | null = null

  private palette: ColorPalette | null = null

  static getInstance(): MardPaletteService {
    if (!MardPaletteService.instance) {
      MardPaletteService.instance = new MardPaletteService()
    }
    return MardPaletteService.instance
  }

  private constructor() {
  }

  /**
   * 初始化调色板数据
   * @param colors 221 个 BeadColor 实例
   */
  initialize(colors: BeadColor[]): void {
    this.palette = new ColorPalette(
      'mard-221',
      'MARD',
      colors,
      5.0,
      'MARD 5mm 标准融合豆色卡 221色'
    )
  }

  /** 获取全部 221 个颜色 */
  getAllColors(): BeadColor[] {
    return this.palette !== null ? this.palette.colors : []
  }

  /** 获取颜色总数 */
  getColorCount(): number {
    return this.palette !== null ? this.palette.getColorCount() : 0
  }

  /**
   * 根据 MARD 色号查询颜色
   * @param code 色号，如 "A1"、"H7"、"M15"
   */
  getColorByCode(code: string): BeadColor | undefined {
    if (this.palette === null) {
      return undefined
    }
    return this.palette.getColorById(code)
  }

  /** 调色板是否已完成初始化 */
  isReady(): boolean {
    return this.palette !== null && this.palette.colors.length > 0
  }
}

/**
 * 颜色匹配结果（由 ColorMappingService 返回）
 */
export class MardColorResult {
  /** MARD 色号，如 "A1" */
  code: string
  /** 十六进制颜色值 */
  hex: string
  /** RGB 数组 [R, G, B] */
  rgb: number[]

  constructor(code: string, hex: string, rgb: number[]) {
    this.code = code
    this.hex = hex
    this.rgb = rgb
  }

  static empty(): MardColorResult {
    return new MardColorResult('', '#000000', [0, 0, 0])
  }
}
