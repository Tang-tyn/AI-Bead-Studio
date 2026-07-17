/**
 * PaletteTestViewModel.ets - 调色板测试页 ViewModel
 *
 * 【职责】
 * 管理 MARD 221 色数据加载、颜色查询、匹配测试的状态。
 * 仅为开发测试用途，不作为最终产品代码。
 */
import { BeadColor } from '../model/BeadColor'
import { MardPaletteService, MardColorResult } from '../service/MardPaletteService'
import { ColorMappingService } from '../service/ColorMappingService'

/** 单个颜色详情（点击时填充） */
export class ColorDetail {
  code: string
  hex: string
  rgb: string

  constructor(code: string, hex: string, rgb: string) {
    this.code = code
    this.hex = hex
    this.rgb = rgb
  }
}

/** JSON 中单个颜色条目 */
interface JsonColorEntry {
  code: string
  hex: string
  rgb: number[]
}

/** JSON 顶层结构 */
interface JsonPaletteData {
  colors: JsonColorEntry[]
}

@Observed
export class PaletteTestViewModel {
  isLoading: boolean = true
  errorMsg: string = ''
  colors: BeadColor[] = []
  colorCount: number = 0
  selectedColor: ColorDetail | null = null
  testResult: MardColorResult | null = null
  testRgb: number[] = [250, 245, 205]

  /**
   * 从 JSON 字符串初始化调色板数据
   * @param jsonText JSON 文本（由 View 层读取 rawfile 后传入）
   */
  initialize(jsonText: string): void {
    this.isLoading = true
    this.errorMsg = ''

    try {
      const jsonData: JsonPaletteData = JSON.parse(jsonText) as JsonPaletteData
      const entries: JsonColorEntry[] = jsonData.colors

      const parsedColors: BeadColor[] = []
      for (let i = 0; i < entries.length; i++) {
        const entry: JsonColorEntry = entries[i]
        parsedColors.push(new BeadColor(
          entry.code,  // id = MARD 色号
          '',           // name: 暂无
          '',           // nameZh: 暂无
          entry.hex,
          entry.rgb
        ))
      }

      MardPaletteService.getInstance().initialize(parsedColors)

      this.colors = parsedColors
      this.colorCount = parsedColors.length
      this.isLoading = false
    } catch (err) {
      this.errorMsg = '数据加载失败'
      this.isLoading = false
    }
  }

  /** 点击颜色 → 显示详情弹窗 */
  selectColor(color: BeadColor): void {
    const rgbText: string = `${color.rgb[0]}, ${color.rgb[1]}, ${color.rgb[2]}`
    this.selectedColor = new ColorDetail(color.id, color.hexColor, rgbText)
  }

  /** 关闭详情弹窗 */
  clearSelection(): void {
    this.selectedColor = null
  }

  /** 测试 Lab Delta E 颜色匹配 */
  runTestMatch(): void {
    this.testResult = ColorMappingService.getInstance()
      .findNearestColor(this.testRgb)
  }
}
