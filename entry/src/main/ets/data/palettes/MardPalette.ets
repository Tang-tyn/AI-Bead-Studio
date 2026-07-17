/**
 * MardPalette.ets - MARD 221 色卡数据加载器
 *
 * 【职责】
 * 从 rawfile/palette/MardPalette.json 读取并解析 MARD 221 色数据。
 *
 * 【DD-008】
 * V1 唯一品牌标准。221 色完整数据。
 *
 * 【使用方式】
 * import { loadMardPalette } from '../data/palettes/MardPalette'
 * const colors = await loadMardPalette(context.resourceManager)
 * MardPaletteService.getInstance().initialize(colors)
 */
import { BeadColor } from '../../model/BeadColor'
import { resourceManager } from '@kit.LocalizationKit'
import { util } from '@kit.ArkTS'

/**
 * JSON 中单个颜色条目的结构（对应 MardPalette.json colors[] 元素）
 */
interface JsonColorEntry {
  code: string
  hex: string
  rgb: number[]
  group: string
  source: string
}

/**
 * JSON 文件顶层结构
 */
interface JsonPaletteData {
  id: string
  title: string
  colors: JsonColorEntry[]
}

/**
 * 从 rawfile 加载并解析 MARD 色卡数据
 *
 * @param resMgr resourceManager 实例（context.resourceManager）
 * @returns 221 个 BeadColor 数组
 */
export async function loadMardPalette(
  resMgr: resourceManager.ResourceManager
): Promise<BeadColor[]> {
  // 读取 rawfile 原始字节
  const rawData: Uint8Array = await resMgr.getRawFileContent('palette/MardPalette.json')

  // 解码为 UTF-8 字符串
  const textDecoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true })
  const jsonText: string = textDecoder.decodeToString(rawData)

  // 解析 JSON 并类型断言为已知结构
  const jsonData: JsonPaletteData = JSON.parse(jsonText) as JsonPaletteData
  const colorsRaw: JsonColorEntry[] = jsonData.colors

  // 转换为 BeadColor 数组
  const colors: BeadColor[] = []
  for (let i = 0; i < colorsRaw.length; i++) {
    const entry: JsonColorEntry = colorsRaw[i]
    colors.push(new BeadColor(
      entry.code,      // id = MARD 色号
      '',              // name: JSON 中暂无
      '',              // nameZh: JSON 中暂无
      entry.hex,
      entry.rgb
    ))
  }

  return colors
}
