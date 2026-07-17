/**
 * ColorMappingService.ets - 颜色匹配服务（基于 Lab + Delta E 76）
 *
 * 【职责】
 * 将任意 RGB 颜色精准匹配到 MARD 221 调色板中最接近的颜色。
 *
 * 【算法链 — DD-009】
 * 输入 RGB → sRGB 线性化 → XYZ（D65）→ Lab → Delta E 76
 * → 遍历 MARD 221 色取最小值 → 返回 {code, hex, rgb}
 */
import { MardPaletteService, MardColorResult } from './MardPaletteService'
import { rgbToLab, deltaE76 } from '../utils/ColorUtils'
import { BeadColor } from '../model/BeadColor'

export class ColorMappingService {
  private static instance: ColorMappingService | null = null

  static getInstance(): ColorMappingService {
    if (!ColorMappingService.instance) {
      ColorMappingService.instance = new ColorMappingService()
    }
    return ColorMappingService.instance
  }

  private constructor() {
  }

  /**
   * 查找与目标 RGB 最接近的 MARD 颜色（Lab + Delta E 76 匹配）
   *
   * @param rgb 目标 RGB [R, G, B]，每个分量 0-255
   * @returns MardColorResult {code, hex, rgb}
   */
  findNearestColor(rgb: number[]): MardColorResult {
    const paletteService: MardPaletteService = MardPaletteService.getInstance()

    if (!paletteService.isReady()) {
      return MardColorResult.empty()
    }

    // 目标颜色 RGB → Lab
    const targetLab: number[] = rgbToLab(rgb)
    const colors: BeadColor[] = paletteService.getAllColors()

    // 遍历 MARD 221 色，找 Delta E 最小的颜色
    let nearestIndex: number = 0
    let minDeltaE: number = Number.MAX_VALUE

    for (let i = 0; i < colors.length; i++) {
      // 每个调色板颜色也转换 Lab（实时计算，221 次 < 2ms）
      const colorLab: number[] = rgbToLab(colors[i].rgb)
      const de: number = deltaE76(targetLab, colorLab)
      if (de < minDeltaE) {
        minDeltaE = de
        nearestIndex = i
      }
    }

    // 使用 Lab 搜索结果构建返回对象
    const best: BeadColor = colors[nearestIndex]
    return new MardColorResult(best.id, best.hexColor, best.rgb)
  }

  /**
   * 批量颜色匹配
   *
   * @param rgbs 目标像素 RGB 数组列表
   * @returns 匹配结果数组（与输入顺序一致）
   */
  findNearestColors(rgbs: number[][]): MardColorResult[] {
    const results: MardColorResult[] = []
    for (let i = 0; i < rgbs.length; i++) {
      results[i] = this.findNearestColor(rgbs[i])
    }
    return results
  }
}
