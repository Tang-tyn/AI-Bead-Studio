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
const TRANSPARENT_ALPHA_MAX: number = 127
const TRANSPARENT_EMPTY_SHARE: number = 0.5
/** 泛洪去白底：RGB 三通道均不低于此值视为近白背景像素（可被挖空）。
 * 取 200 而非 235：放大过的图片轮廓外有一圈模糊过渡带（纯白→灰渐变），
 * 阈值太紧会让过渡带卡在泛洪与暗线优先之间形成黑圈 */
const WHITE_BG_MIN_CHANNEL: number = 200
/** 背景掩码扩张：与背景相邻的浅色像素（三通道均≥此值）并入背景，吃掉泛洪边界外的残留过渡带 */
const WHITE_BG_DILATION_MIN_CHANNEL: number = 180
/** 背景掩码扩张轮数（每轮向浅色像素扩 1 像素） */
const WHITE_BG_DILATION_ROUNDS: number = 2

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
   * @param transparentAsEmpty 背景→空格开关；true 时透明占比过半（含无透明通道图片中泛洪标记的白色背景）的格子留空（colorId=''，异形拼豆），false 时维持白底合成
   * @returns 按 [row][col] 排列且每格存储 MARD 色号的图纸网格
   */
  async generateGridCells(
    pixelMap: image.PixelMap | null,
    gridWidth: number,
    gridHeight: number,
    cancellationToken: ImageProcessingCancellationToken | null,
    progressListener: ImageProcessingProgressListener | null,
    samplingMode: ImageSamplingMode = ImageSamplingMode.PHOTO_AVERAGE,
    cropRect: CropRect | null = null,
    transparentAsEmpty: boolean = false
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

    // 泛洪去白底：开关打开即计算（不限无透明通道的图）——带 alpha 通道但背景为
    // 不透明白色的 PNG 同样需要泛洪；真透明区域由 alpha 路径覆盖，计数互斥不重复。
    // 从剪裁区边缘向内泛洪标记连通白色背景（图内白色不受影响）
    let backgroundMask: Uint8Array | null = null
    if (transparentAsEmpty) {
      backgroundMask = await this.computeWhiteBackgroundMask(
        actualPixelMap, imageWidth, imageHeight, cropX, cropY, cropWidth, cropHeight,
        cancellationToken)
    }

    const pixelBuffer: ArrayBuffer = new ArrayBuffer(rowStride * maximumRegionRows)
    const pixelBytes: Uint8Array = new Uint8Array(pixelBuffer)
    const colorMappingService: ColorMappingService = ColorMappingService.getInstance()
    const cells: GridCell[][] = []
    let nonEmptyCellCount: number = 0

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
        // 背景→空格：统计格子内透明像素数 + 白色背景（泛洪掩码）像素数
        let emptyPixelCount: number = 0

        for (let sourceRow: number = sourceRowStart; sourceRow < sourceRowEnd; sourceRow++) {
          this.throwIfCancelled(cancellationToken)
          const localRow: number = sourceRow - sourceRowStart
          for (let sourceCol: number = sourceColStart; sourceCol < sourceColEnd; sourceCol++) {
            const pixelOffset: number = localRow * rowStride + sourceCol * 4
            const alpha: number = pixelBytes[pixelOffset + 3]
            const alphaRemainder: number = 255 - alpha
            if (transparentAsEmpty && alpha <= TRANSPARENT_ALPHA_MAX) {
              emptyPixelCount += 1
            } else if (backgroundMask !== null &&
              backgroundMask[sourceRow * imageWidth + sourceCol] === 1) {
              // else-if：同一像素不会被透明路径和泛洪路径重复计数
              emptyPixelCount += 1
            }
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
          // 留白行/列（保持宽高比的填充区）：默认填白格；「空格 · 异形」时留空，
          // 成品形状跟随图案而不是上下左右垫一圈白豆
          if (transparentAsEmpty) {
            rowCells.push(new GridCell())
            continue
          }
          if (paddingCode !== '') {
            rowCells.push(new GridCell(paddingCode))
            nonEmptyCellCount += 1
            continue
          }
          throw new Error(`网格单元采样区域为空（${row}, ${col}）`)
        }

        // 众数选桶 + 暗线判定先于空格判定：细线（胡须等）所在格子背景常占比过半，
        // 若先判空格会把细线挖断/挖碎；线条图模式下格子带暗线时黑线优先于空格。
        // （暗线优先冻结版参数：亮度<35、占比≥10%；动漫图模式不做暗线优先，避免柔和色被拖暗）
        let darkLineWins: boolean = false
        let bestCount: number = 0
        let bestRedTotal: number = 0
        let bestGreenTotal: number = 0
        let bestBlueTotal: number = 0
        let darkCount: number = 0
        let darkRedTotal: number = 0
        let darkGreenTotal: number = 0
        let darkBlueTotal: number = 0
        if (bucketStats !== null) {
          // ArkTS 限制：闭包捕获的变量会被装箱，不能对捕获的数组做下标访问，故用标量记录最优桶
          const darkShareThreshold: number = sampleCount * LINE_ART_DARK_MIN_SHARE
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
          darkLineWins = darkCount > 0 && useLineArtMode
        }

        if (!darkLineWins && transparentAsEmpty &&
          emptyPixelCount >= sampleCount * TRANSPARENT_EMPTY_SHARE) {
          // 背景→空格：过半像素为透明或白色背景时整格留空（异形拼豆），不匹配颜色
          rowCells.push(new GridCell())
          continue
        }

        let matchRgb: number[]
        if (bucketStats !== null) {
          if (darkLineWins) {
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
        nonEmptyCellCount += 1
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

    if (transparentAsEmpty && nonEmptyCellCount === 0) {
      throw new Error('图片内容几乎全部为背景（透明或白色），无法生成图纸；可改选「白底」或更换图片')
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

  /**
   * 泛洪去白底：把与剪裁区边缘连通的近白色像素标记为背景。
   * 仅在图片无透明通道且「背景→空格」开关打开时调用；
   * 种子为剪裁区四边上的近白像素，沿 4 邻域扩散，图内不与边缘连通的白色不受影响。
   * @param pixelMap 源图 PixelMap（只读，不修改）
   * @param imageWidth 源图宽（像素），掩码按源图绝对坐标索引
   * @param imageHeight 源图高（像素），用于掩码容量
   * @param cropX 剪裁区左上角横坐标（源图像素）
   * @param cropY 剪裁区左上角纵坐标（源图像素）
   * @param cropWidth 剪裁区宽（像素）
   * @param cropHeight 剪裁区高（像素）
   * @param cancellationToken 可取消令牌
   * @returns 背景掩码（按源图绝对坐标索引，1=背景）；剪裁区外恒为 0
   */
  private async computeWhiteBackgroundMask(
    pixelMap: image.PixelMap,
    imageWidth: number,
    imageHeight: number,
    cropX: number,
    cropY: number,
    cropWidth: number,
    cropHeight: number,
    cancellationToken: ImageProcessingCancellationToken | null
  ): Promise<Uint8Array> {
    // 一次性读入整个剪裁区（最大 2000×2000×4 ≈ 16MB，可接受）
    const cropPixels: ArrayBuffer = new ArrayBuffer(cropWidth * cropHeight * 4)
    const area: image.PositionArea = {
      pixels: cropPixels,
      offset: 0,
      stride: cropWidth * 4,
      region: {
        x: cropX,
        y: cropY,
        size: {
          width: cropWidth,
          height: cropHeight
        }
      }
    }
    try {
      await pixelMap.readPixels(area)
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      throw new Error('读取图片像素失败（去白底）：' + message)
    }
    const bytes: Uint8Array = new Uint8Array(cropPixels)
    const mask: Uint8Array = new Uint8Array(imageWidth * imageHeight)
    // BFS 队列存剪裁区相对下标（localRow * cropWidth + localCol）
    const queue: Int32Array = new Int32Array(cropWidth * cropHeight)
    let queueHead: number = 0
    let queueTail: number = 0

    // 种子：剪裁区四边上的近白像素（缓冲区按剪裁区相对坐标摆放，通道顺序与采样循环一致：红在 +2）
    const totalEdgePixels: number = cropWidth * 2 + cropHeight * 2
    for (let edgeIndex: number = 0; edgeIndex < totalEdgePixels; edgeIndex++) {
      let localCol: number
      let localRow: number
      if (edgeIndex < cropWidth) {
        localCol = edgeIndex
        localRow = 0
      } else if (edgeIndex < cropWidth * 2) {
        localCol = edgeIndex - cropWidth
        localRow = cropHeight - 1
      } else if (edgeIndex < cropWidth * 2 + cropHeight) {
        localCol = 0
        localRow = edgeIndex - cropWidth * 2
      } else {
        localCol = cropWidth - 1
        localRow = edgeIndex - cropWidth * 2 - cropHeight
      }
      const localIndex: number = localRow * cropWidth + localCol
      const pixelOffset: number = localIndex * 4
      const absIndex: number = (cropY + localRow) * imageWidth + cropX + localCol
      if (mask[absIndex] === 0 &&
        bytes[pixelOffset + 2] >= WHITE_BG_MIN_CHANNEL &&
        bytes[pixelOffset + 1] >= WHITE_BG_MIN_CHANNEL &&
        bytes[pixelOffset] >= WHITE_BG_MIN_CHANNEL) {
        mask[absIndex] = 1
        queue[queueTail] = localIndex
        queueTail += 1
      }
    }

    // BFS：4 邻域扩散，仅进入近白像素（图内白色被非白边界挡住，不会被挖掉）
    while (queueHead < queueTail) {
      this.throwIfCancelled(cancellationToken)
      const localIndex: number = queue[queueHead]
      queueHead += 1
      const localRow: number = Math.floor(localIndex / cropWidth)
      const localCol: number = localIndex - localRow * cropWidth
      // 上邻
      if (localRow > 0) {
        const nIndex: number = (localRow - 1) * cropWidth + localCol
        const nOffset: number = nIndex * 4
        const nAbs: number = (cropY + localRow - 1) * imageWidth + cropX + localCol
        if (mask[nAbs] === 0 && bytes[nOffset + 2] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset + 1] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset] >= WHITE_BG_MIN_CHANNEL) {
          mask[nAbs] = 1
          queue[queueTail] = nIndex
          queueTail += 1
        }
      }
      // 下邻
      if (localRow < cropHeight - 1) {
        const nIndex: number = (localRow + 1) * cropWidth + localCol
        const nOffset: number = nIndex * 4
        const nAbs: number = (cropY + localRow + 1) * imageWidth + cropX + localCol
        if (mask[nAbs] === 0 && bytes[nOffset + 2] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset + 1] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset] >= WHITE_BG_MIN_CHANNEL) {
          mask[nAbs] = 1
          queue[queueTail] = nIndex
          queueTail += 1
        }
      }
      // 左邻
      if (localCol > 0) {
        const nIndex: number = localRow * cropWidth + localCol - 1
        const nOffset: number = nIndex * 4
        const nAbs: number = (cropY + localRow) * imageWidth + cropX + localCol - 1
        if (mask[nAbs] === 0 && bytes[nOffset + 2] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset + 1] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset] >= WHITE_BG_MIN_CHANNEL) {
          mask[nAbs] = 1
          queue[queueTail] = nIndex
          queueTail += 1
        }
      }
      // 右邻
      if (localCol < cropWidth - 1) {
        const nIndex: number = localRow * cropWidth + localCol + 1
        const nOffset: number = nIndex * 4
        const nAbs: number = (cropY + localRow) * imageWidth + cropX + localCol + 1
        if (mask[nAbs] === 0 && bytes[nOffset + 2] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset + 1] >= WHITE_BG_MIN_CHANNEL &&
          bytes[nOffset] >= WHITE_BG_MIN_CHANNEL) {
          mask[nAbs] = 1
          queue[queueTail] = nIndex
          queueTail += 1
        }
      }
    }
    // 扩张：把与背景相邻的浅色残留过渡带并入背景，避免其落入暗线优先形成黑圈
    this.dilateWhiteBackgroundMask(
      bytes, mask, imageWidth, cropX, cropY, cropWidth, cropHeight)
    return mask
  }

  /**
   * 背景掩码扩张：每轮把「与背景像素 4 邻域相邻、且三通道均不低于
   * WHITE_BG_DILATION_MIN_CHANNEL 的浅色像素」并入背景，共 WHITE_BG_DILATION_ROUNDS 轮。
   * 深色轮廓（黑线）不满足浅色条件，会挡住扩张——图内白色主体不会被吃掉。
   * @param bytes 剪裁区像素缓冲（computeWhiteBackgroundMask 已读入，通道顺序红在 +2）
   * @param mask 背景掩码（按源图绝对坐标索引，就地修改）
   * @param imageWidth 源图宽（像素）
   * @param cropX 剪裁区左上角横坐标（源图像素）
   * @param cropY 剪裁区左上角纵坐标（源图像素）
   * @param cropWidth 剪裁区宽（像素）
   * @param cropHeight 剪裁区高（像素）
   */
  private dilateWhiteBackgroundMask(
    bytes: Uint8Array,
    mask: Uint8Array,
    imageWidth: number,
    cropX: number,
    cropY: number,
    cropWidth: number,
    cropHeight: number
  ): void {
    for (let round: number = 0; round < WHITE_BG_DILATION_ROUNDS; round++) {
      // 本轮新增用独立数组记录，避免迭代顺序导致扩张方向各向异性
      const added: Uint8Array = new Uint8Array(cropWidth * cropHeight)
      for (let localRow: number = 0; localRow < cropHeight; localRow++) {
        for (let localCol: number = 0; localCol < cropWidth; localCol++) {
          const localIndex: number = localRow * cropWidth + localCol
          const absIndex: number = (cropY + localRow) * imageWidth + cropX + localCol
          if (mask[absIndex] === 1 || added[localIndex] === 1) {
            continue
          }
          const pixelOffset: number = localIndex * 4
          // 浅色判定：三通道均不低于扩张阈值（深色轮廓被挡住，白主体在轮廓内侧也接触不到）
          if (bytes[pixelOffset + 2] < WHITE_BG_DILATION_MIN_CHANNEL ||
            bytes[pixelOffset + 1] < WHITE_BG_DILATION_MIN_CHANNEL ||
            bytes[pixelOffset] < WHITE_BG_DILATION_MIN_CHANNEL) {
            continue
          }
          // 4 邻域任一已是背景（含本轮新增）即并入
          let touchesBackground: boolean = false
          if (localRow > 0) {
            const nIndex: number = localIndex - cropWidth
            if (mask[(cropY + localRow - 1) * imageWidth + cropX + localCol] === 1 ||
              added[nIndex] === 1) {
              touchesBackground = true
            }
          }
          if (!touchesBackground && localRow < cropHeight - 1) {
            const nIndex: number = localIndex + cropWidth
            if (mask[(cropY + localRow + 1) * imageWidth + cropX + localCol] === 1 ||
              added[nIndex] === 1) {
              touchesBackground = true
            }
          }
          if (!touchesBackground && localCol > 0) {
            const nIndex: number = localIndex - 1
            if (mask[(cropY + localRow) * imageWidth + cropX + localCol - 1] === 1 ||
              added[nIndex] === 1) {
              touchesBackground = true
            }
          }
          if (!touchesBackground && localCol < cropWidth - 1) {
            const nIndex: number = localIndex + 1
            if (mask[(cropY + localRow) * imageWidth + cropX + localCol + 1] === 1 ||
              added[nIndex] === 1) {
              touchesBackground = true
            }
          }
          if (touchesBackground) {
            added[localIndex] = 1
          }
        }
      }
      // 合并本轮新增到掩码
      let hasAddition: boolean = false
      for (let localIndex: number = 0; localIndex < cropWidth * cropHeight; localIndex++) {
        if (added[localIndex] === 1) {
          const localRow: number = Math.floor(localIndex / cropWidth)
          const localCol: number = localIndex - localRow * cropWidth
          mask[(cropY + localRow) * imageWidth + cropX + localCol] = 1
          hasAddition = true
        }
      }
      if (!hasAddition) {
        break
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
