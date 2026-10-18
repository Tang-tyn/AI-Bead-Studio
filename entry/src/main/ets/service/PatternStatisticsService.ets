/**
 * PatternStatisticsService.ets - 按最终图纸统计实际 MARD 用色与材料数量
 */
import { BeadPattern } from '../model/BeadPattern'
import { GridCell } from '../model/GridCell'
import { BeadColor } from '../model/BeadColor'
import { PatternColorCount, PatternStatistics } from '../model/PatternStatistics'
import { MardPaletteService } from './MardPaletteService'
import { GRID_MAX_SIZE, GRID_MIN_SIZE } from '../utils/Constants'

const MARD_PALETTE_ID: string = 'mard-221'

export class PatternStatisticsService {
  private static instance: PatternStatisticsService | null = null

  static getInstance(): PatternStatisticsService {
    if (PatternStatisticsService.instance === null) {
      PatternStatisticsService.instance = new PatternStatisticsService()
    }
    return PatternStatisticsService.instance
  }

  private constructor() {
  }

  /**
   * 统计有效 MARD 色号的用量；空格不计，缺失格和无效色号计入异常数量。
   * @param pattern 当前生成的图纸
   * @returns 按图纸行列顺序排列的用色数量、总颗数和异常格数
   */
  calculate(pattern: BeadPattern): PatternStatistics {
    if (pattern.paletteId !== MARD_PALETTE_ID) {
      throw new Error('图纸未使用当前 MARD 221 色卡，无法统计材料')
    }
    if (!Number.isInteger(pattern.gridWidth) ||
      !Number.isInteger(pattern.gridHeight) ||
      pattern.gridWidth < GRID_MIN_SIZE || pattern.gridWidth > GRID_MAX_SIZE ||
      pattern.gridHeight < GRID_MIN_SIZE || pattern.gridHeight > GRID_MAX_SIZE) {
      throw new Error('图纸网格尺寸无效，无法统计材料')
    }

    const paletteService: MardPaletteService = MardPaletteService.getInstance()
    if (!paletteService.isReady() || paletteService.getColorCount() !== 221) {
      throw new Error('MARD 221 色卡尚未完整初始化，无法统计材料')
    }

    const colorByCode: Map<string, BeadColor> = new Map<string, BeadColor>()
    const paletteColors: BeadColor[] = paletteService.getAllColors()
    for (let i: number = 0; i < paletteColors.length; i++) {
      colorByCode.set(paletteColors[i].id, paletteColors[i])
    }

    const countsByCode: Map<string, PatternColorCount> = new Map<string, PatternColorCount>()
    const resultColors: PatternColorCount[] = []
    let totalBeads: number = 0
    let invalidCellCount: number = 0

    for (let row: number = 0; row < pattern.gridHeight; row++) {
      const rowCells: GridCell[] | undefined = pattern.cells[row]
      for (let col: number = 0; col < pattern.gridWidth; col++) {
        if (rowCells === undefined || col >= rowCells.length || rowCells[col] === undefined) {
          invalidCellCount++
          continue
        }

        const colorCode: string = rowCells[col].colorId
        if (colorCode === '') {
          continue
        }
        const beadColor: BeadColor | undefined = colorByCode.get(colorCode)
        if (beadColor === undefined || !/^#[0-9A-Fa-f]{6}$/.test(beadColor.hexColor)) {
          invalidCellCount++
          continue
        }

        let colorCount: PatternColorCount | undefined = countsByCode.get(colorCode)
        if (colorCount === undefined) {
          colorCount = new PatternColorCount(colorCode, beadColor.hexColor, 0)
          countsByCode.set(colorCode, colorCount)
          resultColors.push(colorCount)
        }
        colorCount.count++
        totalBeads++
      }
    }

    return new PatternStatistics(resultColors, totalBeads, invalidCellCount)
  }
}
