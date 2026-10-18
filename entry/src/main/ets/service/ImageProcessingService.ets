/**
 * ImageProcessingService.ets - 将 PixelMap 区域采样并映射为 MARD 图纸网格
 */
import { image } from '@kit.ImageKit'
import { GridCell } from '../model/GridCell'
import { GRID_MAX_SIZE, GRID_MIN_SIZE, IMAGE_MAX_HEIGHT, IMAGE_MAX_WIDTH } from '../utils/Constants'
import { ColorMappingService } from './ColorMappingService'
import { MardPaletteService } from './MardPaletteService'

const MARD_PALETTE_COLOR_COUNT: number = 221

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
   * @returns 按 [row][col] 排列且每格存储 MARD 色号的图纸网格
   */
  async generateGridCells(
    pixelMap: image.PixelMap | null,
    gridWidth: number,
    gridHeight: number,
    cancellationToken: ImageProcessingCancellationToken | null,
    progressListener: ImageProcessingProgressListener | null
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

    const maximumRegionRows: number = Math.max(1, Math.ceil(imageHeight / gridHeight))
    const pixelBuffer: ArrayBuffer = new ArrayBuffer(rowStride * maximumRegionRows)
    const pixelBytes: Uint8Array = new Uint8Array(pixelBuffer)
    const colorMappingService: ColorMappingService = ColorMappingService.getInstance()
    const cells: GridCell[][] = []

    if (progressListener !== null) {
      progressListener.onProgress(0, gridHeight)
    }
    this.throwIfCancelled(cancellationToken)
    await this.yieldToNextEventLoop()

    for (let row: number = 0; row < gridHeight; row++) {
      this.throwIfCancelled(cancellationToken)

      const sourceRowStart: number = Math.floor(row * imageHeight / gridHeight)
      const sourceRowEnd: number = Math.min(
        imageHeight,
        Math.max(sourceRowStart + 1, Math.floor((row + 1) * imageHeight / gridHeight))
      )
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

      try {
        await actualPixelMap.readPixels(area)
      } catch (err) {
        const message: string = err instanceof Error ? err.message : '未知错误'
        throw new Error('读取图片像素失败：' + message)
      }
      this.throwIfCancelled(cancellationToken)

      const rowCells: GridCell[] = []
      for (let col: number = 0; col < gridWidth; col++) {
        this.throwIfCancelled(cancellationToken)

        const sourceColStart: number = Math.floor(col * imageWidth / gridWidth)
        const sourceColEnd: number = Math.min(
          imageWidth,
          Math.max(sourceColStart + 1, Math.floor((col + 1) * imageWidth / gridWidth))
        )
        let redTotal: number = 0
        let greenTotal: number = 0
        let blueTotal: number = 0
        let sampleCount: number = 0

        for (let sourceRow: number = sourceRowStart; sourceRow < sourceRowEnd; sourceRow++) {
          this.throwIfCancelled(cancellationToken)
          const localRow: number = sourceRow - sourceRowStart
          for (let sourceCol: number = sourceColStart; sourceCol < sourceColEnd; sourceCol++) {
            const pixelOffset: number = localRow * rowStride + sourceCol * 4
            const alpha: number = pixelBytes[pixelOffset + 3]
            const alphaRemainder: number = 255 - alpha

            if (imageInfo.alphaType === image.AlphaType.OPAQUE) {
              redTotal += pixelBytes[pixelOffset + 2]
              greenTotal += pixelBytes[pixelOffset + 1]
              blueTotal += pixelBytes[pixelOffset]
            } else if (imageInfo.alphaType === image.AlphaType.PREMUL) {
              redTotal += Math.min(255, pixelBytes[pixelOffset + 2] + alphaRemainder)
              greenTotal += Math.min(255, pixelBytes[pixelOffset + 1] + alphaRemainder)
              blueTotal += Math.min(255, pixelBytes[pixelOffset] + alphaRemainder)
            } else {
              redTotal += Math.round(
                (pixelBytes[pixelOffset + 2] * alpha + 255 * alphaRemainder) / 255
              )
              greenTotal += Math.round(
                (pixelBytes[pixelOffset + 1] * alpha + 255 * alphaRemainder) / 255
              )
              blueTotal += Math.round(
                (pixelBytes[pixelOffset] * alpha + 255 * alphaRemainder) / 255
              )
            }
            sampleCount++
          }
        }

        if (sampleCount === 0) {
          throw new Error(`网格单元采样区域为空（${row}, ${col}）`)
        }

        const averageRgb: number[] = [
          Math.round(redTotal / sampleCount),
          Math.round(greenTotal / sampleCount),
          Math.round(blueTotal / sampleCount)
        ]
        const matchedColor = colorMappingService.findNearestColor(averageRgb)
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

    return cells
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
