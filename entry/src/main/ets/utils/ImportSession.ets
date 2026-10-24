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
import { CropRect } from '../model/CropRect'

export class ImageImportData {
  pixelMap: image.PixelMap | null
  gridWidth: number
  gridHeight: number
  sourceImageUri: string
  /** 图纸风格序号（页面选择顺序）：0=照片 / 1=动漫图 / 2=线条图 */
  styleIndex: number
  cropRect: CropRect | null
  /** 背景→空格开关：true 时透明像素或泛洪标记的白色背景占比过半的格子留空（异形拼豆） */
  transparentAsEmpty: boolean

  constructor(
    pixelMap: image.PixelMap | null,
    gridWidth: number,
    gridHeight: number,
    sourceImageUri: string,
    styleIndex: number,
    cropRect: CropRect | null = null,
    transparentAsEmpty: boolean = false
  ) {
    this.pixelMap = pixelMap
    this.gridWidth = gridWidth
    this.gridHeight = gridHeight
    this.sourceImageUri = sourceImageUri
    this.styleIndex = styleIndex
    this.cropRect = cropRect
    this.transparentAsEmpty = transparentAsEmpty
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
