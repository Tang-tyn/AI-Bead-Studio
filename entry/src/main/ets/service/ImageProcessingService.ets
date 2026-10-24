/**
 * ImageProcessingService.ets - 将 PixelMap 区域采样并映射为 MARD 图纸网格
 */
import { image } from '@kit.ImageKit'
import { GridCell } from '../model/GridCell'
import { CropRect } from '../model/CropRect'
import { BeadColor } from '../model/BeadColor'
import { GRID_MAX_SIZE, GRID_MIN_SIZE, IMAGE_MAX_HEIGHT, IMAGE_MAX_WIDTH } from '../utils/Constants'
import { ColorMappingService } from './ColorMappingService'
import { MardPaletteService } from './MardPaletteService'

const MARD_PALETTE_COLOR_COUNT: number = 221

/**
 * 采样模式：
 * - PHOTO_AVERAGE：区域像素平均（照片类图片颜色过渡自然）
 * - LINE_ART_MODE：区域内占多数的量化色平均 + 暗线优先 + 色彩精简（白底黑线稿细线清晰）
 * - ANIME_MODE：区域内占多数的量化色平均，无暗线优先、无色彩精简（平涂动漫图色块干净、少数色保留）
 */
export enum ImageSamplingMode {
  PHOTO_AVERAGE = 0,
  LINE_ART_MODE = 1,
  ANIME_MODE = 2
}

const LINE_ART_TRIM_WHITE_MIN: number = 240
const LINE_ART_ALPHA_MIN: number = 33
const LINE_ART_DARK_LUMINANCE: number = 35
const LINE_ART_DARK_MIN_SHARE: number = 0.1
const LINE_ART_MAX_COLORS: number = 6
const TRIM_MIN_PIXEL_ABS: number = 3
const TRIM_PROJECTION_PEAK_RATIO: number = 0.05
const TRIM_SCAN_BAND_ROWS: number = 32

/**
 * 内容边界框（线条图模式裁白边用），坐标为原图像素。
 */
class ContentBounds {
  readonly minX: number
  readonly minY: number
  readonly width: number
  readonly height: number

  constructor(minX: number, minY: number, width: number, height: number) {
    this.minX = minX
    this.minY = minY
    this.width = width
    this.height = height
  }
}

/**
 * 色号出现频次（线条图模式色彩精简的排序单元）。
 */
class ColorFrequency {
  code: string
  count: number

  constructor(code: string, count: number) {
    this.code = code
    this.count = count
  }
}

/**
 * 图像转换取消令牌；调用方可在分批处理期间请求取消。
 */
export class ImageProcessingCancellationToken {
  private cancelled: boolean = false

  /**
   * 请求取消当前转换。
   * @returns 无返回值
   */
  cancel(): void {
    this.cancelled = true
  }

  /**
   * 查询当前转换是否已请求取消。
   * @returns 是否已请求取消
   */
  isCancelled(): boolean {
    return this.cancelled
  }
}

/**
 * 图像转换进度监听器；进度以已完成网格行数表示。
 */
export interface ImageProcessingProgressListener {
  /**
   * 接收图像转换进度。
   * @param completedRows 已完成的网格行数
   * @param totalRows 网格总行数
   * @returns 无返回值
   */
  onProgress(completedRows: number, totalRows: number): void
}

/**
 * MARD 色卡未完整初始化、输入无效或转换失败时，由调用方接收此服务抛出的错误。
 */
export class ImageProcessingService {
  private static instance: ImageProcessingService | null = null
  private regionBucketStats: Map<number, number[]> = new Map<number, number[]>()

  /**
   * 获取图像处理服务单例。
   * @returns 图像处理服务实例
   */
  static getInstance(): ImageProcessingService {
    if (ImageProcessingService.instance === null) {
      ImageProcessingService.instance = new ImageProcessingService()
    }
    return ImageProcessingService.instance
  }

  private constructor() {
  }

  /**
   * 将输入 PixelMap 按指定网格尺寸采样并匹配到 MARD 221 色。
   *
   * PixelMap 由调用方持有；本方法只借用像素资源，不会释放它。
   *
   * @param pixelMap 待处理图片；为空时拒绝转换
   * @param gridWidth 目标网格列数，范围 10–200
   * @param gridHeight 目标网格行数，范围 10–200
   * @param cancellationToken 可取消令牌；不需要取消时传入 null
   * @param progressListener 进度监听器；不需要进度时传入 null
   * @param samplingMode 采样模式；线条图模式取区域众数量化色，避免细线被平均成灰色
   * @param cropRect 剪裁区域（源图像素坐标）；null 表示整张图。仅作采样偏移，不修改原 PixelMap
   * @returns 按 [row][col] 排列且每格存储 MARD 色号的图纸网格
   */
  async generateGridCells(
    pixelMap: image.PixelMap | null,
    gridWidth: number,
    gridHeight: number,
    cancellationToken: ImageProcessingCancellationToken | null,
    progressListener: ImageProcessingProgressListener | null,
    samplingMode: ImageSamplingMode = ImageSamplingMode.PHOTO_AVERAGE,
    cropRect: CropRect | null = null
  ): Promise<GridCell[][]> {
    if (pixelMap === null) {
      throw new Error('待转换的 PixelMap 为空')
    }
    this.validateGridSize(gridWidth, gridHeight)
    this.throwIfCancelled(cancellationToken)

    const actualPixelMap: image.PixelMap = pixelMap
    const imageInfo: image.ImageInfo = await this.getImageInfo(actualPixelMap)
    this.throwIfCancelled(cancellationToken)
    const imageWidth: number = imageInfo.size.width
    const imageHeight: number = imageInfo.size.height
    this.validateImageInfo(imageInfo, imageWidth, imageHeight)

    const rowStride: number = actualPixelMap.getBytesNumberPerRow()
    const totalPixelBytes: number = actualPixelMap.getPixelBytesNumber()
    const minimumRowBytes: number = imageWidth * 4
    if (!Number.isInteger(rowStride) || rowStride < minimumRowBytes ||
      rowStride !== imageInfo.stride ||
      totalPixelBytes < rowStride * imageHeight) {
      throw new Error('图片像素步长或缓冲区大小无效')
    }

    const paletteService: MardPaletteService = MardPaletteService.getInstance()
    if (!paletteService.isReady() || paletteService.getColorCount() !== MARD_PALETTE_COLOR_COUNT) {
      throw new Error('MARD 221 色卡尚未完整初始化，无法生成图纸')
    }

    const paletteColors = paletteService.getAllColors()
    const paletteColorCodes: Set<string> = new Set<string>()
    for (let colorIndex: number = 0; colorIndex < paletteColors.length; colorIndex++) {
      const colorCode: string = paletteColors[colorIndex].id
      if (!/^[A-Z][0-9]+$/.test(colorCode)) {
        throw new Error(`MARD 色卡包含无效色号：${colorCode}`)
      }
      if (paletteColorCodes.has(colorCode)) {
        throw new Error(`MARD 色卡包含重复色号：${colorCode}`)
      }
      paletteColorCodes.add(colorCode)
    }

    const useLineArtMode: boolean = samplingMode === ImageSamplingMode.LINE_ART_MODE
    // 众数量化桶采样：线条图与动漫图共用（动漫图不做暗线优先、不精简色彩）
    const useBucketSampling: boolean = samplingMode !== ImageSamplingMode.PHOTO_AVERAGE
    const maximumRegionRows: number = Math.max(1, Math.ceil(imageHeight / gridHeight))

    // 剪裁区域：钳制到图片范围（源图像素坐标）；null 表示整张图。
    // 只约束采样与扫描范围，原 PixelMap 保持完整（"返回重新生成"依赖完整原图）
    let cropX: number = 0
    let cropY: number = 0
    let cropWidth: number = imageWidth
    let cropHeight: number = imageHeight
    if (cropRect !== null) {
      if (!CropRect.isValid(cropRect.x, cropRect.y, cropRect.width, cropRect.height)) {
        throw new Error('剪裁区域无效，无法生成图纸')
      }
      cropX = Math.min(imageWidth - 1, Math.max(0, cropRect.x))
      cropY = Math.min(imageHeight - 1, Math.max(0, cropRect.y))
      cropWidth = Math.min(imageWidth - cropX, cropRect.width)
      cropHeight = Math.min(imageHeight - cropY, cropRect.height)
    }

    // 扫描内容边界框，裁掉四周纯白/透明边，让主体占满格子（两种模式通用；扫描限定在剪裁区域内）
    let contentMinX: number = cropX
    let contentMinY: number = cropY
    let contentWidth: number = cropWidth
    let contentHeight: number = cropHeight
    const bounds: ContentBounds | null =
      await this.findContentBounds(
        actualPixelMap, imageInfo, imageWidth, imageHeight, cropX, cropY, cropWidth, cropHeight)
    if (bounds === null) {
      if (useBucketSampling) {
        throw new Error('未检测到图片内容（整张图接近纯白），无法生成图纸')
      }
    } else {
      contentMinX = bounds.minX
      contentMinY = bounds.minY
      contentWidth = bounds.width
      contentHeight = bounds.height
    }

    const pixelBuffer: ArrayBuffer = new ArrayBuffer(rowStride * maximumRegionRows)
    const pixelBytes: Uint8Array = new Uint8Array(pixelBuffer)
    const colorMappingService: ColorMappingService = ColorMappingService.getInstance()
    const cells: GridCell[][] = []

    // 内容框按宽高比适配网格，短的一维居中留白，避免图案被拉伸变形（两种模式通用）
    let sampleRowStartGrid: number = 0
    let sampleRows: number = gridHeight
    let sampleColStartGrid: number = 0
    let sampleCols: number = gridWidth
    let paddingCode: string = ''
    if (contentWidth >= contentHeight) {
      sampleCols = gridWidth
      sampleRows = Math.min(
        gridHeight, Math.max(1, Math.round(gridWidth * contentHeight / contentWidth)))
    } else {
      sampleRows = gridHeight
      sampleCols = Math.min(
        gridWidth, Math.max(1, Math.round(gridHeight * contentWidth / contentHeight)))
    }
    sampleRowStartGrid = Math.floor((gridHeight - sampleRows) / 2)
    sampleColStartGrid = Math.floor((gridWidth - sampleCols) / 2)
    const whiteMatch = colorMappingService.findNearestColor([255, 255, 255])
    paddingCode = whiteMatch.code

    if (progressListener !== null) {
      progressListener.onProgress(0, gridHeight)
    }
    this.throwIfCancelled(cancellationToken)
    await this.yieldToNextEventLoop()

    for (let row: number = 0; row < gridHeight; row++) {
      this.throwIfCancelled(cancellationToken)

      const relRow: number = row - sampleRowStartGrid
      let relRowStart: number = 0
      let relRowEnd: number = 0
      if (relRow >= 0 && relRow < sampleRows) {
        relRowStart = Math.floor(relRow * contentHeight / sampleRows)
        relRowEnd = Math.min(
          contentHeight,
          Math.max(relRowStart + 1, Math.floor((relRow + 1) * contentHeight / sampleRows))
        )
      }
      const sourceRowStart: number = contentMinY + relRowStart
      const sourceRowEnd: number = contentMinY + relRowEnd
      const sourceRowCount: number = sourceRowEnd - sourceRowStart
      const area: image.PositionArea = {
        pixels: pixelBuffer,
        offset: 0,
        stride: rowStride,
        region: {
          x: 0,
          y: sourceRowStart,
          size: {
            width: imageWidth,
            height: sourceRowCount
          }
        }
      }

      if (sourceRowCount > 0) {
        try {
          await actualPixelMap.readPixels(area)
        } catch (err) {
          const message: string = err instanceof Error ? err.message : '未知错误'
          throw new Error('读取图片像素失败：' + message)
        }
        this.throwIfCancelled(cancellationToken)
      }

      const rowCells: GridCell[] = []
      for (let col: number = 0; col < gridWidth; col++) {
        this.throwIfCancelled(cancellationToken)

        const relCol: number = col - sampleColStartGrid
        let relColStart: number = 0
        let relColEnd: number = 0
        if (relCol >= 0 && relCol < sampleCols) {
          relColStart = Math.floor(relCol * contentWidth / sampleCols)
          relColEnd = Math.min(
            contentWidth,
            Math.max(relColStart + 1, Math.floor((relCol + 1) * contentWidth / sampleCols))
          )
        }
        const sourceColStart: number = contentMinX + relColStart
        const sourceColEnd: number = contentMinX + relColEnd
        let redTotal: number = 0
        let greenTotal: number = 0
        let blueTotal: number = 0
        let sampleCount: number = 0
        // 众数量化桶采样（线条图/动漫图）：按 16 级/通道量化统计区域众数桶（复用 Map 减少分配）
        let bucketStats: Map<number, number[]> | null = null
        if (useBucketSampling) {
          bucketStats = this.regionBucketStats
          bucketStats.clear()
        }

        for (let sourceRow: number = sourceRowStart; sourceRow < sourceRowEnd; sourceRow++) {
          this.throwIfCancelled(cancellationToken)
          const localRow: number = sourceRow - sourceRowStart
          for (let sourceCol: number = sourceColStart; sourceCol < sourceColEnd; sourceCol++) {
            const pixelOffset: number = localRow * rowStride + sourceCol * 4
            const alpha: number = pixelBytes[pixelOffset + 3]
            const alphaRemainder: number = 255 - alpha
            let pixelRed: number
            let pixelGreen: number
            let pixelBlue: number

            if (imageInfo.alphaType === image.AlphaType.OPAQUE) {
              pixelRed = pixelBytes[pixelOffset + 2]
              pixelGreen = pixelBytes[pixelOffset + 1]
              pixelBlue = pixelBytes[pixelOffset]
            } else if (imageInfo.alphaType === image.AlphaType.PREMUL) {
              pixelRed = Math.min(255, pixelBytes[pixelOffset + 2] + alphaRemainder)
              pixelGreen = Math.min(255, pixelBytes[pixelOffset + 1] + alphaRemainder)
              pixelBlue = Math.min(255, pixelBytes[pixelOffset] + alphaRemainder)
            } else {
              pixelRed = Math.round(
                (pixelBytes[pixelOffset + 2] * alpha + 255 * alphaRemainder) / 255
              )
              pixelGreen = Math.round(
                (pixelBytes[pixelOffset + 1] * alpha + 255 * alphaRemainder) / 255
              )
              pixelBlue = Math.round(
                (pixelBytes[pixelOffset] * alpha + 255 * alphaRemainder) / 255
              )
            }
            redTotal += pixelRed
            greenTotal += pixelGreen
            blueTotal += pixelBlue

            if (bucketStats !== null) {
              const bucketKey: number =
                ((pixelRed >> 4) << 8) | ((pixelGreen >> 4) << 4) | (pixelBlue >> 4)
              const bucket: number[] | undefined = bucketStats.get(bucketKey)
              if (bucket === undefined) {
                bucketStats.set(bucketKey, [1, pixelRed, pixelGreen, pixelBlue])
              } else {
                bucket[0] += 1
                bucket[1] += pixelRed
                bucket[2] += pixelGreen
                bucket[3] += pixelBlue
              }
            }
            sampleCount++
          }
        }

        if (sampleCount === 0) {
          // 留白行/列（保持宽高比的填充区）填白格；防御性兜底：无留白色号时报错
          if (paddingCode !== '') {
            rowCells.push(new GridCell(paddingCode))
            continue
          }
          throw new Error(`网格单元采样区域为空（${row}, ${col}）`)
        }

        let matchRgb: number[]
        if (bucketStats !== null) {
          // 众数选桶 + 暗线优先（线条图算法冻结版：亮度<35、占比≥10%）
          // ArkTS 限制：闭包捕获的变量会被装箱，不能对捕获的数组做下标访问，故用标量记录最优桶
          const darkShareThreshold: number = sampleCount * LINE_ART_DARK_MIN_SHARE
          let bestCount: number = 0
          let bestRedTotal: number = 0
          let bestGreenTotal: number = 0
          let bestBlueTotal: number = 0
          let darkCount: number = 0
          let darkRedTotal: number = 0
          let darkGreenTotal: number = 0
          let darkBlueTotal: number = 0
          bucketStats.forEach((bucket: number[]) => {
            if (bucket[0] > bestCount) {
              bestCount = bucket[0]
              bestRedTotal = bucket[1]
              bestGreenTotal = bucket[2]
              bestBlueTotal = bucket[3]
            }
            const bucketLuma: number =
              (299 * bucket[1] + 587 * bucket[2] + 114 * bucket[3]) / (1000 * bucket[0])
            if (bucketLuma < LINE_ART_DARK_LUMINANCE && bucket[0] >= darkShareThreshold &&
              bucket[0] > darkCount) {
              darkCount = bucket[0]
              darkRedTotal = bucket[1]
              darkGreenTotal = bucket[2]
              darkBlueTotal = bucket[3]
            }
          })
          if (bestCount === 0) {
            throw new Error(`采样区域统计为空（${row}, ${col}）`)
          }
          // 暗线优先仅线条图模式：亮度<35 的暗桶占比≥10% 时整格选暗，保细线连通；
          // 动漫图模式不做暗线优先，避免蓝眼睛/浅阴影等柔和色被拖暗
          if (darkCount > 0 && useLineArtMode) {
            matchRgb = [
              Math.round(darkRedTotal / darkCount),
              Math.round(darkGreenTotal / darkCount),
              Math.round(darkBlueTotal / darkCount)
            ]
          } else {
            matchRgb = [
              Math.round(bestRedTotal / bestCount),
              Math.round(bestGreenTotal / bestCount),
              Math.round(bestBlueTotal / bestCount)
            ]
          }
        } else {
          matchRgb = [
            Math.round(redTotal / sampleCount),
            Math.round(greenTotal / sampleCount),
            Math.round(blueTotal / sampleCount)
          ]
        }
        const matchedColor = colorMappingService.findNearestColor(matchRgb)
        if (!paletteColorCodes.has(matchedColor.code)) {
          throw new Error(`颜色匹配返回非当前 MARD 色卡色号：${matchedColor.code}`)
        }
        rowCells.push(new GridCell(matchedColor.code))
      }

      cells.push(rowCells)
      if (progressListener !== null) {
        progressListener.onProgress(row + 1, gridHeight)
      }
      this.throwIfCancelled(cancellationToken)
      if (row + 1 < gridHeight) {
        await this.yieldToNextEventLoop()
      }
    }

    if (useLineArtMode) {
      this.simplifyLineArtColors(cells, paletteService)
    }

    return cells
  }

  /**
   * 线条图模式：分波段扫描图片，计算内容边界框。
   * 内容判定：不透明且颜色不在接近纯白范围（忽略白底与透明边）。
   * @param pixelMap 待扫描的图片
   * @param imageInfo 图片信息（Alpha 类型判定用）
   * @param imageWidth 图片宽（像素）
   * @param imageHeight 图片高（像素）
   * @param scanX 扫描区域左上角横坐标（像素，剪裁偏移）
   * @param scanY 扫描区域左上角纵坐标（像素，剪裁偏移）
   * @param scanWidth 扫描区域宽（像素）
   * @param scanHeight 扫描区域高（像素）
   * @returns 内容边界框；扫描区域内无内容时返回 null
   */
  private async findContentBounds(
    pixelMap: image.PixelMap,
    imageInfo: image.ImageInfo,
    imageWidth: number,
    imageHeight: number,
    scanX: number,
    scanY: number,
    scanWidth: number,
    scanHeight: number
  ): Promise<ContentBounds | null> {
    const rowStride: number = pixelMap.getBytesNumberPerRow()
    const bandRows: number = Math.min(TRIM_SCAN_BAND_ROWS, imageHeight)
    const buffer: ArrayBuffer = new ArrayBuffer(rowStride * bandRows)
    const bytes: Uint8Array = new Uint8Array(buffer)
    // 行/列投影计数：一行/列的非白像素达到阈值才算内容，过滤零星 JPEG 噪点
    // 阈值在扫描结束后按投影峰值自适应计算（见下方），此处不预设
    // 投影数组保持全图尺寸（下标即全图坐标），仅扫描范围限定在剪裁区域内
    const rowCount: Int32Array = new Int32Array(imageHeight)
    const colCount: Int32Array = new Int32Array(imageWidth)

    for (let bandStart: number = scanY; bandStart < scanY + scanHeight; bandStart += bandRows) {
      const bandHeight: number = Math.min(bandRows, scanY + scanHeight - bandStart)
      const area: image.PositionArea = {
        pixels: buffer,
        offset: 0,
        stride: rowStride,
        region: {
          x: scanX,
          y: bandStart,
          size: {
            width: scanWidth,
            height: bandHeight
          }
        }
      }
      try {
        await pixelMap.readPixels(area)
      } catch (err) {
        const message: string = err instanceof Error ? err.message : '未知错误'
        throw new Error('扫描图片内容边界失败：' + message)
      }

      for (let localRow: number = 0; localRow < bandHeight; localRow++) {
        const rowBase: number = localRow * rowStride
        for (let col: number = scanX; col < scanX + scanWidth; col++) {
          // readPixels 的 region.x=scanX 表示源图起始列，但缓冲区数据从 0 开始摆放，
          // 因此缓冲区下标必须用剪裁区域内的相对列号，否则剪裁框不贴左边缘时右侧内容全部丢失
          const offset: number = rowBase + (col - scanX) * 4
          const alpha: number = imageInfo.alphaType === image.AlphaType.OPAQUE
            ? 255 : bytes[offset + 3]
          if (alpha <= LINE_ART_ALPHA_MIN) {
            continue
          }
          const red: number = bytes[offset + 2]
          const green: number = bytes[offset + 1]
          const blue: number = bytes[offset]
          if (red >= LINE_ART_TRIM_WHITE_MIN && green >= LINE_ART_TRIM_WHITE_MIN &&
            blue >= LINE_ART_TRIM_WHITE_MIN) {
            continue
          }
          const y: number = bandStart + localRow
          rowCount[y] += 1
          colCount[col] += 1
        }
      }
    }

    let minX: number = -1
    let maxX: number = -1
    let minY: number = -1
    let maxY: number = -1
    // 自适应阈值：内容行的深色像素数远高于噪点行，取投影峰值的 5% 可稳定区分两者
    let peakRowCount: number = 0
    let peakColCount: number = 0
    for (let y: number = 0; y < imageHeight; y++) {
      if (rowCount[y] > peakRowCount) {
        peakRowCount = rowCount[y]
      }
    }
    for (let col: number = 0; col < imageWidth; col++) {
      if (colCount[col] > peakColCount) {
        peakColCount = colCount[col]
      }
    }
    const colThreshold: number = Math.max(
      TRIM_MIN_PIXEL_ABS, Math.floor(peakColCount * TRIM_PROJECTION_PEAK_RATIO))
    const rowThreshold: number = Math.max(
      TRIM_MIN_PIXEL_ABS, Math.floor(peakRowCount * TRIM_PROJECTION_PEAK_RATIO))
    for (let col: number = 0; col < imageWidth; col++) {
      if (colCount[col] >= colThreshold) {
        if (minX < 0) {
          minX = col
        }
        maxX = col
      }
    }
    for (let y: number = 0; y < imageHeight; y++) {
      if (rowCount[y] >= rowThreshold) {
        if (minY < 0) {
          minY = y
        }
        maxY = y
      }
    }
    if (minX < 0 || minY < 0) {
      return null
    }
    return new ContentBounds(minX, minY, maxX - minX + 1, maxY - minY + 1)
  }

  /**
   * 线条图模式色彩精简：统计全图色号频次，仅保留数量前 LINE_ART_MAX_COLORS 的主色，
   * 其余色号就地归并到 RGB 距离最近的主色，去除杂灰与过渡色。
   * 注意：只改色号引用，不改变任何格子的空间分布（线条粗细/位置不受影响）。
   * @param cells 已生成的图纸网格（就地修改）
   * @param paletteService MARD 色卡服务（色号转 RGB 用）
   */
  private simplifyLineArtColors(cells: GridCell[][], paletteService: MardPaletteService): void {
    const frequency: Map<string, number> = new Map<string, number>()
    for (let row: number = 0; row < cells.length; row++) {
      for (let col: number = 0; col < cells[row].length; col++) {
        const code: string = cells[row][col].colorId
        if (code === '') {
          continue
        }
        const count: number | undefined = frequency.get(code)
        if (count === undefined) {
          frequency.set(code, 1)
        } else {
          frequency.set(code, count + 1)
        }
      }
    }

    const ranked: ColorFrequency[] = []
    frequency.forEach((count: number, code: string) => {
      ranked.push(new ColorFrequency(code, count))
    })
    ranked.sort((a: ColorFrequency, b: ColorFrequency) => b.count - a.count)
    if (ranked.length <= LINE_ART_MAX_COLORS) {
      return
    }

    const keptRgb: Map<string, number[]> = new Map<string, number[]>()
    for (let i: number = 0; i < LINE_ART_MAX_COLORS; i++) {
      const bead: BeadColor | undefined = paletteService.getColorByCode(ranked[i].code)
      if (bead !== undefined) {
        keptRgb.set(ranked[i].code, bead.rgb)
      }
    }

    for (let row: number = 0; row < cells.length; row++) {
      for (let col: number = 0; col < cells[row].length; col++) {
        const code: string = cells[row][col].colorId
        if (code === '' || keptRgb.has(code)) {
          continue
        }
        const bead: BeadColor | undefined = paletteService.getColorByCode(code)
        if (bead === undefined) {
          continue
        }
        const beadRed: number = bead.rgb[0]
        const beadGreen: number = bead.rgb[1]
        const beadBlue: number = bead.rgb[2]
        let bestCode: string = ''
        let bestDistance: number = -1
        keptRgb.forEach((rgb: number[], keptCode: string) => {
          const dr: number = beadRed - rgb[0]
          const dg: number = beadGreen - rgb[1]
          const db: number = beadBlue - rgb[2]
          const distance: number = dr * dr + dg * dg + db * db
          if (bestDistance < 0 || distance < bestDistance) {
            bestDistance = distance
            bestCode = keptCode
          }
        })
        if (bestCode !== '') {
          cells[row][col].colorId = bestCode
        }
      }
    }
  }


  private validateGridSize(gridWidth: number, gridHeight: number): void {
    if (!Number.isInteger(gridWidth) || gridWidth < GRID_MIN_SIZE || gridWidth > GRID_MAX_SIZE ||
      !Number.isInteger(gridHeight) || gridHeight < GRID_MIN_SIZE || gridHeight > GRID_MAX_SIZE) {
      throw new Error(`网格宽高必须是 ${GRID_MIN_SIZE}–${GRID_MAX_SIZE} 之间的整数`)
    }
  }

  private async getImageInfo(pixelMap: image.PixelMap): Promise<image.ImageInfo> {
    try {
      return await pixelMap.getImageInfo()
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      throw new Error('读取图片信息失败：' + message)
    }
  }

  private validateImageInfo(
    imageInfo: image.ImageInfo,
    imageWidth: number,
    imageHeight: number
  ): void {
    if (!Number.isInteger(imageWidth) || !Number.isInteger(imageHeight) ||
      imageWidth <= 0 || imageHeight <= 0 ||
      imageWidth > IMAGE_MAX_WIDTH || imageHeight > IMAGE_MAX_HEIGHT) {
      throw new Error('图片尺寸无效或超过允许的最大尺寸')
    }
    if (imageInfo.pixelFormat !== image.PixelMapFormat.RGBA_8888) {
      throw new Error('图片像素格式不是 RGBA_8888，无法安全采样')
    }
    if (imageInfo.alphaType !== image.AlphaType.OPAQUE &&
      imageInfo.alphaType !== image.AlphaType.PREMUL &&
      imageInfo.alphaType !== image.AlphaType.UNPREMUL) {
      throw new Error('图片 Alpha 格式无法识别，无法按白底规则合成')
    }
  }

  private throwIfCancelled(cancellationToken: ImageProcessingCancellationToken | null): void {
    if (cancellationToken !== null && cancellationToken.isCancelled()) {
      throw new Error('图纸生成已取消')
    }
  }

  private async yieldToNextEventLoop(): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve()
      }, 0)
    })
  }
}
