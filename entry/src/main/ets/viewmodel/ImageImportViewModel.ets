/**
 * ImageImportViewModel.ets - 图片导入 ViewModel
 */
import { ImagePickerService } from '../service/ImagePickerService'
import { image } from '@kit.ImageKit'
import { ImageImportData } from '../utils/ImportSession'

interface GridPreset {
  label: string
  width: number
  height: number
}

@Observed
export class ImageImportViewModel {
  isLoading: boolean = false
  errorMsg: string = ''
  selectedUri: string = ''
  previewPixelMap: image.PixelMap | null = null

  readonly presets: GridPreset[] = [
    { label: '29 × 29', width: 29, height: 29 },
    { label: '58 × 58', width: 58, height: 58 },
    { label: '87 × 87', width: 87, height: 87 }
  ]

  selectedPresetIndex: number = 1

  get gridWidth(): number {
    return this.presets[this.selectedPresetIndex].width
  }

  get gridHeight(): number {
    return this.presets[this.selectedPresetIndex].height
  }

  selectPreset(index: number): void {
    if (index >= 0 && index < this.presets.length) {
      this.selectedPresetIndex = index
    }
  }

  /**
   * 打开相册 → 选择图片 → 加载 PixelMap
   */
  async pickAndLoadImage(): Promise<void> {
    const pickerService: ImagePickerService = ImagePickerService.getInstance()

    this.isLoading = true
    this.errorMsg = ''

    const uri: string = await pickerService.pickImage()

    if (uri === '') {
      this.isLoading = false
      return
    }

    this.selectedUri = uri

    const pixelMap: image.PixelMap | null = await pickerService.loadPixelMap(uri)

    if (pixelMap === null) {
      this.errorMsg = '图片加载失败，请重试'
      this.isLoading = false
      return
    }

    this.previewPixelMap = pixelMap
    this.isLoading = false
  }

  resetImage(): void {
    if (this.previewPixelMap !== null) {
      this.previewPixelMap.release()
    }
    this.selectedUri = ''
    this.previewPixelMap = null
    this.errorMsg = ''
    this.isLoading = false
  }

  /**
   * 构建传递给 Phase 3 的数据对象
   */
  buildImportData(): ImageImportData {
    return new ImageImportData(
      this.previewPixelMap,
      this.gridWidth,
      this.gridHeight,
      this.selectedUri
    )
  }

  get hasImage(): boolean {
    return this.previewPixelMap !== null && this.selectedUri !== ''
  }
}
