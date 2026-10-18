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
import { rgbToLab } from '../utils/ColorUtils'
import { resourceManager } from '@kit.LocalizationKit'
import { loadMardPalette } from '../data/palettes/MardPalette'

const MARD_PALETTE_COLOR_COUNT: number = 221

export class MardPaletteService {
  private static instance: MardPaletteService | null = null

  private palette: ColorPalette | null = null
  private initializationPromise: Promise<void> | null = null

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
    this.validateColors(colors)

    for (let i = 0; i < colors.length; i++) {
      colors[i].lab = rgbToLab(colors[i].rgb)
    }

    const initializedPalette: ColorPalette = new ColorPalette(
      'mard-221',
      'MARD',
      colors,
      5.0,
      'MARD 5mm 标准融合豆色卡 221色'
    )
    this.palette = initializedPalette
  }

  private validateColors(colors: BeadColor[]): void {
    if (colors.length !== MARD_PALETTE_COLOR_COUNT) {
      throw new Error(`色卡颜色数量应为 ${MARD_PALETTE_COLOR_COUNT}，实际为 ${colors.length}`)
    }

    const colorCodes: Set<string> = new Set<string>()
    for (let i = 0; i < colors.length; i++) {
      const color: BeadColor = colors[i]
      if (!/^[A-Z][0-9]+$/.test(color.id)) {
        throw new Error(`MARD 色卡包含无效色号：${color.id}`)
      }
      if (colorCodes.has(color.id)) {
        throw new Error(`MARD 色卡包含重复色号：${color.id}`)
      }
      colorCodes.add(color.id)
      if (color.rgb.length !== 3 ||
        !Number.isInteger(color.rgb[0]) || color.rgb[0] < 0 || color.rgb[0] > 255 ||
        !Number.isInteger(color.rgb[1]) || color.rgb[1] < 0 || color.rgb[1] > 255 ||
        !Number.isInteger(color.rgb[2]) || color.rgb[2] < 0 || color.rgb[2] > 255) {
        throw new Error(`MARD 色卡颜色 ${color.id} 的 RGB 数据无效`)
      }
    }
  }

  /**
   * 确保 MARD 221 色卡已加载；并发请求共享同一次加载。
   * @param resMgr 应用资源管理器
   * @returns 初始化完成时 resolve；加载失败或色卡无效时 reject
   */
  async ensureInitialized(resMgr: resourceManager.ResourceManager): Promise<void> {
    if (this.isReady()) {
      return
    }

    if (this.initializationPromise === null) {
      this.initializationPromise = this.loadPalette(resMgr)
    }

    try {
      await this.initializationPromise
    } finally {
      this.initializationPromise = null
    }
  }

  private async loadPalette(resMgr: resourceManager.ResourceManager): Promise<void> {
    try {
      const colors: BeadColor[] = await loadMardPalette(resMgr)
      this.initialize(colors)
      if (!this.isReady() || this.getColorCount() !== MARD_PALETTE_COLOR_COUNT) {
        throw new Error('MARD 色卡初始化后状态无效')
      }
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      throw new Error('加载 MARD 221 色卡失败：' + message)
    }
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
    return this.palette !== null &&
      this.palette.id === 'mard-221' &&
      this.palette.colors.length === MARD_PALETTE_COLOR_COUNT
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
