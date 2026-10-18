/**
 * ImportSession.ets - 图片导入数据暂存
 *
 * 【职责】
 * Phase 2（图片导入）→ Phase 3（图纸生成）的数据桥梁。
 * PixelMap 无法通过路由参数传递，使用单例暂存。
 *
 * 【使用】
 * Phase 2: ImportSession.save(result)
 * Phase 3: const data = ImportSession.consume()  // 读取后清空
 */
import { image } from '@kit.ImageKit'

export class ImageImportData {
  pixelMap: image.PixelMap | null
  gridWidth: number
  gridHeight: number
  sourceImageUri: string

  constructor(
    pixelMap: image.PixelMap | null,
    gridWidth: number,
    gridHeight: number,
    sourceImageUri: string
  ) {
    this.pixelMap = pixelMap
    this.gridWidth = gridWidth
    this.gridHeight = gridHeight
    this.sourceImageUri = sourceImageUri
  }
}

export class ImportSession {
  private static data: ImageImportData | null = null

  static save(data: ImageImportData): void {
    if (ImportSession.data !== null && ImportSession.data.pixelMap !== data.pixelMap) {
      if (ImportSession.data.pixelMap !== null) {
        ImportSession.releasePixelMap(ImportSession.data.pixelMap)
      }
    }
    ImportSession.data = data
  }

  static consume(): ImageImportData | null {
    const result: ImageImportData | null = ImportSession.data
    ImportSession.data = null
    return result
  }

  static clear(): void {
    if (ImportSession.data !== null && ImportSession.data.pixelMap !== null) {
      ImportSession.releasePixelMap(ImportSession.data.pixelMap)
    }
    ImportSession.data = null
  }

  static hasData(): boolean {
    return ImportSession.data !== null
  }

  private static releasePixelMap(pixelMap: image.PixelMap): void {
    pixelMap.release().catch((err: Error) => {
      console.error('释放暂存图片资源失败: ' + err.message)
    })
  }
}
