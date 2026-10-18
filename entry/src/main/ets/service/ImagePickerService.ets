/**
 * ImagePickerService.ets - 图片选择与加载服务
 *
 * 【API】HarmonyOS NEXT API 24
 * photoAccessHelper.PhotoViewPicker → URI → fileIo.openSync → fd →
 * image.createImageSource(fd) → ImageSource.createPixelMap() → PixelMap
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { image } from '@kit.ImageKit'
import { fileIo } from '@kit.CoreFileKit'
import { GRID_MIN_SIZE } from '../utils/Constants'

const MAX_DECODED_IMAGE_DIMENSION: number = 2000
const DETAIL_SAMPLE_MAX_DIMENSION: number = 64
const DETAIL_EDGE_THRESHOLD: number = 24

/** 图片复杂度分析结果，用于给网格尺寸提供非强制建议 */
export class ImageGridRecommendation {
  gridWidth: number
  gridHeight: number
  detailLevel: string

  constructor(gridWidth: number, gridHeight: number, detailLevel: string) {
    this.gridWidth = gridWidth
    this.gridHeight = gridHeight
    this.detailLevel = detailLevel
  }
}

/** 已加载的图片及其网格尺寸建议 */
export class LoadedImportImage {
  pixelMap: image.PixelMap
  recommendation: ImageGridRecommendation | null
  recommendationError: string

  constructor(
    pixelMap: image.PixelMap,
    recommendation: ImageGridRecommendation | null,
    recommendationError: string
  ) {
    this.pixelMap = pixelMap
    this.recommendation = recommendation
    this.recommendationError = recommendationError
  }
}

export class ImagePickerService {
  private static instance: ImagePickerService | null = null

  static getInstance(): ImagePickerService {
    if (!ImagePickerService.instance) {
      ImagePickerService.instance = new ImagePickerService()
    }
    return ImagePickerService.instance
  }

  private constructor() {
  }

  /**
   * 打开系统相册选择器，返回选中图片 URI。取消时返回 ''
   * @returns 选中图片 URI；用户取消时为空字符串
   */
  async pickImage(): Promise<string> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker()
      const pickResult: photoAccessHelper.PhotoSelectResult = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      })
      if (pickResult.photoUris.length > 0) {
        return pickResult.photoUris[0]
      }
      return ''
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      throw new Error(`打开相册失败：${message}`)
    }
  }

  /**
   * 从 URI 加载 PixelMap（通过文件描述符方式）
   * @param uri 已选择图片的 URI
   * @returns 图片像素及基于缩略采样的网格建议
   */
  async loadPixelMap(uri: string): Promise<LoadedImportImage> {
    if (uri === '') {
      throw new Error('图片地址为空')
    }

    let file: fileIo.File | null = null
    let imageSource: image.ImageSource | null = null
    let decodedPixelMap: image.PixelMap | null = null
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
      imageSource = image.createImageSource(file.fd)
      const imageInfo: image.ImageInfo = await imageSource.getImageInfo()
      const originalWidth: number = imageInfo.size.width
      const originalHeight: number = imageInfo.size.height
      if (!(originalWidth > 0) || !(originalHeight > 0)) {
        throw new Error('图片尺寸无效')
      }

      const resizeRatio: number = Math.min(
        1,
        MAX_DECODED_IMAGE_DIMENSION / originalWidth,
        MAX_DECODED_IMAGE_DIMENSION / originalHeight
      )
      const targetWidth: number = Math.max(1, Math.round(originalWidth * resizeRatio))
      const targetHeight: number = Math.max(1, Math.round(originalHeight * resizeRatio))
      decodedPixelMap = await imageSource.createPixelMap({
        desiredSize: { width: targetWidth, height: targetHeight },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      })

      const pixelMap: image.PixelMap = decodedPixelMap
      let recommendation: ImageGridRecommendation | null = null
      let recommendationError: string = ''
      try {
        recommendation = await this.analyzeImageDetail(
          imageSource,
          originalWidth,
          originalHeight
        )
      } catch (err) {
        const message: string = err instanceof Error ? err.message : '未知错误'
        console.error('图片细节分析失败: ' + message)
        recommendationError = '细节分析暂不可用，请手动选择网格尺寸'
      }

      await imageSource.release()
      imageSource = null
      decodedPixelMap = null
      return new LoadedImportImage(pixelMap, recommendation, recommendationError)
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      throw new Error(`图片加载失败：${message}`)
    } finally {
      try {
        if (imageSource !== null) {
          await imageSource.release()
        }
      } catch (err) {
        const message: string = err instanceof Error ? err.message : '未知错误'
        console.error('释放图片源失败: ' + message)
      }
      if (file !== null) {
        try {
          fileIo.closeSync(file)
        } catch (err) {
          const message: string = err instanceof Error ? err.message : '未知错误'
          console.error('关闭图片文件失败: ' + message)
        }
      }
      if (decodedPixelMap !== null) {
        decodedPixelMap.release().catch((err: Error) => {
          console.error('释放未交付图片资源失败: ' + err.message)
        })
      }
    }
  }

  private async analyzeImageDetail(
    imageSource: image.ImageSource,
    originalWidth: number,
    originalHeight: number
  ): Promise<ImageGridRecommendation> {
    const resizeRatio: number = Math.min(
      1,
      DETAIL_SAMPLE_MAX_DIMENSION / originalWidth,
      DETAIL_SAMPLE_MAX_DIMENSION / originalHeight
    )
    const sampleWidth: number = Math.max(2, Math.round(originalWidth * resizeRatio))
    const sampleHeight: number = Math.max(2, Math.round(originalHeight * resizeRatio))
    const samplePixelMap: image.PixelMap = await imageSource.createPixelMap({
      desiredSize: { width: sampleWidth, height: sampleHeight },
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    })

    try {
      const sampleInfo: image.ImageInfo = await samplePixelMap.getImageInfo()
      const rowStride: number = samplePixelMap.getBytesNumberPerRow()
      const pixels: ArrayBuffer = new ArrayBuffer(samplePixelMap.getPixelBytesNumber())
      await samplePixelMap.readPixelsToBuffer(pixels)
      const pixelBytes: Uint8Array = new Uint8Array(pixels)
      const edgeDensity: number = this.calculateEdgeDensity(
        pixelBytes,
        sampleInfo.size.width,
        sampleInfo.size.height,
        rowStride
      )
      return this.createRecommendation(edgeDensity, originalWidth, originalHeight)
    } finally {
      await samplePixelMap.release()
    }
  }

  private calculateEdgeDensity(
    pixels: Uint8Array,
    sampleWidth: number,
    sampleHeight: number,
    rowStride: number
  ): number {
    let edgeCount: number = 0
    let comparisonCount: number = 0

    for (let row = 0; row < sampleHeight; row++) {
      for (let col = 0; col < sampleWidth; col++) {
        const pixelOffset: number = row * rowStride + col * 4

        if (col + 1 < sampleWidth) {
          if (this.hasSignificantColorChange(pixels, pixelOffset, pixelOffset + 4)) {
            edgeCount++
          }
          comparisonCount++
        }
        if (row + 1 < sampleHeight) {
          if (this.hasSignificantColorChange(pixels, pixelOffset, pixelOffset + rowStride)) {
            edgeCount++
          }
          comparisonCount++
        }
      }
    }

    return comparisonCount > 0 ? edgeCount / comparisonCount : 0
  }

  private hasSignificantColorChange(pixels: Uint8Array, firstOffset: number, secondOffset: number): boolean {
    return Math.abs(pixels[firstOffset] - pixels[secondOffset]) >= DETAIL_EDGE_THRESHOLD ||
      Math.abs(pixels[firstOffset + 1] - pixels[secondOffset + 1]) >= DETAIL_EDGE_THRESHOLD ||
      Math.abs(pixels[firstOffset + 2] - pixels[secondOffset + 2]) >= DETAIL_EDGE_THRESHOLD
  }

  private createRecommendation(
    edgeDensity: number,
    originalWidth: number,
    originalHeight: number
  ): ImageGridRecommendation {
    let longSide: number = 29
    let detailLevel: string = '较简单'
    if (edgeDensity >= 0.38) {
      longSide = 174
      detailLevel = '非常丰富'
    } else if (edgeDensity >= 0.28) {
      longSide = 145
      detailLevel = '丰富'
    } else if (edgeDensity >= 0.19) {
      longSide = 116
      detailLevel = '较丰富'
    } else if (edgeDensity >= 0.11) {
      longSide = 87
      detailLevel = '中等'
    } else if (edgeDensity >= 0.055) {
      longSide = 58
      detailLevel = '较简单'
    }

    const aspectRatio: number = originalWidth / originalHeight
    let gridWidth: number = longSide
    let gridHeight: number = longSide
    if (aspectRatio >= 1) {
      gridHeight = Math.max(GRID_MIN_SIZE, Math.round(longSide / aspectRatio))
    } else {
      gridWidth = Math.max(GRID_MIN_SIZE, Math.round(longSide * aspectRatio))
    }

    return new ImageGridRecommendation(gridWidth, gridHeight, detailLevel)
  }
}
