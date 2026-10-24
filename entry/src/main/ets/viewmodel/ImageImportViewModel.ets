/**
 * ImageImportViewModel.ets - 图片导入 ViewModel
 */
import {
  ImageGridRecommendation,
  ImagePickerService,
  LoadedImportImage
} from '../service/ImagePickerService'
import { image } from '@kit.ImageKit'
import { ImageImportData, ImportSession } from '../utils/ImportSession'
import { CropRect } from '../model/CropRect'
import {
  ImageProcessingCancellationToken,
  ImageProcessingProgressListener,
  ImageProcessingService,
  ImageSamplingMode
} from '../service/ImageProcessingService'
import { MardPaletteService } from '../service/MardPaletteService'
import { BeadPattern } from '../model/BeadPattern'
import { GridCell } from '../model/GridCell'
import { Project, ProjectStatus } from '../model/Project'
import { PatternSession } from '../utils/PatternSession'
import { GRID_MAX_SIZE, GRID_MIN_SIZE } from '../utils/Constants'
import { resourceManager } from '@kit.LocalizationKit'
import { common } from '@kit.AbilityKit'
import { PatternColorCount, PatternStatistics } from '../model/PatternStatistics'
import { PatternStatisticsService } from '../service/PatternStatisticsService'
import { PatternExportService } from '../service/PatternExportService'

const MARD_PALETTE_ID: string = 'mard-221'

interface GridPreset {
  label: string
  width: number
  height: number
}

@Observed
export class ImageImportViewModel {
  isLoading: boolean = false
  isGenerating: boolean = false
  errorMsg: string = ''
  conversionProgress: number = 0
  conversionCompletedRows: number = 0
  conversionTotalRows: number = 0
  generatedProject: Project | null = null
  previewColorByCode: Map<string, string> = new Map<string, string>()
  patternStatistics: PatternStatistics | null = null
  isShowingGeneratedPreview: boolean = false
  isExportingPng: boolean = false
  exportFeedback: string = ''
  selectedUri: string = ''
  previewPixelMap: image.PixelMap | null = null
  recommendation: ImageGridRecommendation | null = null
  recommendationError: string = ''
  customGridWidthText: string = ''
  customGridHeightText: string = ''
  private isActive: boolean = true
  private requestGeneration: number = 0
  private generationTaskSequence: number = 0
  private activeGenerationTaskId: number = 0
  private exportTaskSequence: number = 0
  private activeExportTaskId: number = 0
  private cancellationToken: ImageProcessingCancellationToken | null = null
  private static generatedIdSequence: number = 0

  readonly presets: GridPreset[] = [
    { label: '29 × 29', width: 29, height: 29 },
    { label: '58 × 58', width: 58, height: 58 },
    { label: '87 × 87', width: 87, height: 87 }
  ]

  selectedPresetIndex: number = -1
  isCustomSizeSelected: boolean = false
  /** 图纸风格序号（页面选择顺序）：0=照片（区域平均）/ 1=动漫图（众数量化色）/ 2=线条图（众数量化+暗线优先+色彩精简） */
  styleIndex: number = 0
  /** 剪裁区域（源图像素坐标）；null 表示未剪裁，使用整张图 */
  cropRect: CropRect | null = null
  /** 剪裁后的展示图（仅用于预览显示；生成始终用原图 + cropRect 采样，原 PixelMap 不动） */
  croppedPreviewPixelMap: image.PixelMap | null = null

  get gridWidth(): number {
    if (this.isCustomSizeSelected) {
      return this.getCustomDimension(this.customGridWidthText)
    }
    if (this.selectedPresetIndex < 0 && this.recommendation !== null) {
      return this.recommendation.gridWidth
    }
    if (this.selectedPresetIndex < 0) {
      return this.presets[1].width
    }
    return this.presets[this.selectedPresetIndex].width
  }

  get gridHeight(): number {
    if (this.isCustomSizeSelected) {
      return this.getCustomDimension(this.customGridHeightText)
    }
    if (this.selectedPresetIndex < 0 && this.recommendation !== null) {
      return this.recommendation.gridHeight
    }
    if (this.selectedPresetIndex < 0) {
      return this.presets[1].height
    }
    return this.presets[this.selectedPresetIndex].height
  }

  get isGridSizeValid(): boolean {
    return this.gridWidth >= GRID_MIN_SIZE && this.gridWidth <= GRID_MAX_SIZE &&
      this.gridHeight >= GRID_MIN_SIZE && this.gridHeight <= GRID_MAX_SIZE
  }

  get customGridError(): string {
    if (!this.isCustomSizeSelected || this.isGridSizeValid) {
      return ''
    }
    return `宽高请输入 ${GRID_MIN_SIZE}–${GRID_MAX_SIZE} 之间的整数`
  }

  selectPreset(index: number): void {
    if (index >= 0 && index < this.presets.length) {
      this.selectedPresetIndex = index
      this.isCustomSizeSelected = false
    }
  }

  selectRecommendation(): void {
    this.selectedPresetIndex = -1
    this.isCustomSizeSelected = false
  }

  selectCustomSize(): void {
    this.customGridWidthText = `${this.gridWidth}`
    this.customGridHeightText = `${this.gridHeight}`
    this.isCustomSizeSelected = true
    this.selectedPresetIndex = -1
  }

  updateCustomGridWidth(value: string): void {
    this.customGridWidthText = value
  }

  updateCustomGridHeight(value: string): void {
    this.customGridHeightText = value
  }

  /**
   * 打开相册 → 选择图片 → 加载 PixelMap
   */
  async pickAndLoadImage(): Promise<void> {
    if (this.isLoading || !this.isActive) {
      return
    }

    this.clearGeneratedPreview()
    const pickerService: ImagePickerService = ImagePickerService.getInstance()
    const requestGeneration: number = ++this.requestGeneration

    this.isLoading = true
    this.errorMsg = ''

    try {
      const uri: string = await pickerService.pickImage()
      if (uri === '' || !this.isCurrentRequest(requestGeneration)) {
        return
      }

      const loadResult: LoadedImportImage = await pickerService.loadPixelMap(uri)
      if (!this.isCurrentRequest(requestGeneration)) {
        this.releasePixelMap(loadResult.pixelMap)
        return
      }

      const previousPixelMap: image.PixelMap | null = this.previewPixelMap
      this.previewPixelMap = loadResult.pixelMap
      this.selectedUri = uri
      this.recommendation = loadResult.recommendation
      this.recommendationError = loadResult.recommendationError
      this.cropRect = null
      this.releaseCroppedPreview()
      this.selectedPresetIndex = -1
      this.isCustomSizeSelected = false
      if (loadResult.recommendation !== null) {
        this.customGridWidthText = `${loadResult.recommendation.gridWidth}`
        this.customGridHeightText = `${loadResult.recommendation.gridHeight}`
      } else {
        this.customGridWidthText = `${this.presets[1].width}`
        this.customGridHeightText = `${this.presets[1].height}`
      }
      if (previousPixelMap !== null) {
        this.releasePixelMap(previousPixelMap)
      }
    } catch (err) {
      if (this.isCurrentRequest(requestGeneration)) {
        const message: string = err instanceof Error ? err.message : '图片导入失败，请重试'
        console.error('图片导入失败: ' + message)
        this.errorMsg = message
      }
    } finally {
      if (requestGeneration === this.requestGeneration) {
        this.isLoading = false
      }
    }
  }

  /**
   * 设置页面活动状态，避免页面离开后异步加载结果泄漏。
   * @param active 页面是否处于活动状态
   */
  setActive(active: boolean): void {
    if (this.isActive === active) {
      return
    }
    this.isActive = active
    this.resetImage()
  }

  /**
   * 将图片资源临时移交给生成任务；任务结束后由当前任务归还或释放。
   * @returns 图片导入数据；当前没有有效图片时返回 null
   */
  takeImportData(): ImageImportData | null {
    if (!this.hasImage) {
      return null
    }

    const data: ImageImportData = new ImageImportData(
      this.previewPixelMap,
      this.gridWidth,
      this.gridHeight,
      this.selectedUri,
      this.styleIndex,
      this.cropRect
    )
    this.previewPixelMap = null
    return data
  }

  /**
   * 从图纸预览返回图片与尺寸设置；原 PixelMap 仍由 ViewModel 持有。
   * @returns 无返回值
   */
  returnToImageSettings(): void {
    if (this.hasImage && this.generatedProject !== null) {
      this.clearGeneratedPreview()
    }
  }

  /**
   * 消费 ImportSession 图片数据，生成图纸与内存项目，并在任务完成后归还原图资源。
   * @param resMgr 应用资源管理器
   * @returns 转换完成时 resolve；失败或取消时设置 errorMsg
   */
  async generatePattern(resMgr: resourceManager.ResourceManager): Promise<void> {
    if (this.isGenerating) {
      return
    }

    const importData: ImageImportData | null = ImportSession.consume()
    if (importData === null) {
      this.errorMsg = '没有可生成的图片数据，请重新选择图片'
      return
    }

    let ownedPixelMap: image.PixelMap | null = importData.pixelMap
    const taskId: number = ++this.generationTaskSequence
    this.activeGenerationTaskId = taskId
    this.isGenerating = true
    this.errorMsg = ''
    this.conversionProgress = 0
    this.conversionCompletedRows = 0
    this.clearGeneratedPreview()
    this.conversionTotalRows = importData.gridHeight
    const token: ImageProcessingCancellationToken = new ImageProcessingCancellationToken()
    this.cancellationToken = token

    try {
      if (ownedPixelMap === null) {
        throw new Error('导入数据中的 PixelMap 为空')
      }
      if (!this.isValidGridSize(importData.gridWidth, importData.gridHeight)) {
        throw new Error(`网格宽高必须是 ${GRID_MIN_SIZE}–${GRID_MAX_SIZE} 之间的整数`)
      }
      if (!this.isActive || token.isCancelled()) {
        throw new Error('图纸生成已取消')
      }

      await MardPaletteService.getInstance().ensureInitialized(resMgr)
      if (!this.isActive || token.isCancelled()) {
        throw new Error('图纸生成已取消')
      }

      const generatedCells: GridCell[][] =
        await ImageProcessingService.getInstance().generateGridCells(
          ownedPixelMap,
          importData.gridWidth,
          importData.gridHeight,
          token,
          new ImageImportProgressListener(this, taskId),
          this.styleToSamplingMode(importData.styleIndex),
          importData.cropRect
        )
      this.validateGeneratedCells(
        generatedCells,
        importData.gridWidth,
        importData.gridHeight
      )
      if (!this.isActive || token.isCancelled()) {
        throw new Error('图纸生成已取消')
      }

      const createdAt: number = Date.now()
      const pattern: BeadPattern = new BeadPattern(
        this.createGeneratedId('pattern'),
        '图片转图纸',
        importData.gridWidth,
        importData.gridHeight,
        MARD_PALETTE_ID,
        generatedCells,
        createdAt,
        createdAt
      )
      const project: Project = new Project(
        this.createGeneratedId('project'),
        '图片转图纸',
        pattern,
        importData.sourceImageUri,
        '',
        ProjectStatus.DRAFT,
        createdAt,
        createdAt
      )

      if (!this.isCurrentGenerationTask(taskId) || token.isCancelled()) {
        throw new Error('图纸生成已取消')
      }

      const statistics: PatternStatistics =
        PatternStatisticsService.getInstance().calculate(pattern)
      const previewColorByCode: Map<string, string> =
        this.createPreviewColorMap(statistics.colors)
      if (!this.isCurrentGenerationTask(taskId) || token.isCancelled()) {
        throw new Error('图纸生成已取消')
      }
      PatternSession.save(project)
      this.generatedProject = project
      this.patternStatistics = statistics
      this.previewColorByCode = previewColorByCode
      this.isShowingGeneratedPreview = true
      this.conversionProgress = 100
      this.conversionCompletedRows = importData.gridHeight
    } catch (err) {
      if (this.isCurrentGenerationTask(taskId)) {
        const message: string = err instanceof Error ? err.message : '图纸生成失败，请重试'
        console.error('图纸生成失败：' + message)
        this.errorMsg = message
      }
    } finally {
      if (ownedPixelMap !== null) {
        if (this.isCurrentGenerationTask(taskId)) {
          this.previewPixelMap = ownedPixelMap
          this.selectedUri = importData.sourceImageUri
          ownedPixelMap = null
        } else {
          await this.releaseOwnedPixelMap(ownedPixelMap)
        }
      }
      if (this.isCurrentGenerationTask(taskId)) {
        if (this.cancellationToken === token) {
          this.cancellationToken = null
        }
        this.isGenerating = false
      }
    }
  }

  /**
   * 将当前生成图纸保存到系统图库；只在图库保存确认后报告成功。
   * @param context UIAbility 上下文
   * @returns 导出流程完成时 resolve
   */
  async exportGeneratedPatternPng(context: common.UIAbilityContext): Promise<void> {
    await this.exportGeneratedPattern(context, true)
  }

  /**
   * 将当前生成图纸保存到用户指定的文件位置。
   * @param context UIAbility 上下文
   * @returns 导出流程完成时 resolve
   */
  async exportGeneratedPatternPngToLocation(context: common.UIAbilityContext): Promise<void> {
    await this.exportGeneratedPattern(context, false)
  }

  private async exportGeneratedPattern(
    context: common.UIAbilityContext,
    toGallery: boolean
  ): Promise<void> {
    const project: Project | null = this.generatedProject
    const statistics: PatternStatistics | null = this.patternStatistics
    if (project === null || statistics === null || this.isExportingPng) {
      return
    }

    const taskId: number = ++this.exportTaskSequence
    this.activeExportTaskId = taskId
    this.isExportingPng = true
    this.exportFeedback = ''
    try {
      const exportService: PatternExportService = PatternExportService.getInstance()
      const saved: boolean = toGallery
        ? await exportService.exportToGallery(project.pattern, statistics, context)
        : await exportService.exportToLocation(project.pattern, statistics, context)
      if (this.isCurrentExportTask(taskId, project)) {
        if (saved) {
          this.exportFeedback = toGallery ? '图纸已保存到图库' : 'PNG 图纸已保存到指定位置'
        } else {
          this.exportFeedback = toGallery ? '已取消保存到图库' : '已取消保存'
        }
      }
    } catch (err) {
      if (this.isCurrentExportTask(taskId, project)) {
        const message: string = err instanceof Error ? err.message : '未知错误'
        console.error('图纸导出失败：' + message)
        this.exportFeedback = 'PNG 导出失败：' + message
      }
    } finally {
      if (this.isCurrentExportTask(taskId, project)) {
        this.isExportingPng = false
      }
    }
  }

  /**
   * 更新当前图纸生成任务的行进度。
   * @param taskId 生成任务标识
   * @param completedRows 已完成的网格行数
   * @param totalRows 网格总行数
   * @returns 无返回值
   */
  updateProgressForTask(taskId: number, completedRows: number, totalRows: number): void {
    if (this.isCurrentGenerationTask(taskId)) {
      this.conversionTotalRows = totalRows
      this.conversionCompletedRows = completedRows
      this.conversionProgress = Math.floor(completedRows * 100 / totalRows)
    }
  }

  /**
   * 请求取消当前转换；同步处理当前网格行结束后才会观察到请求。
   * @returns 无返回值
   */
  cancelGeneration(): void {
    if (this.cancellationToken !== null) {
      this.cancellationToken.cancel()
    }
  }

  resetImage(): void {
    this.requestGeneration++
    this.invalidateGenerationTask()
    if (this.previewPixelMap !== null) {
      this.releasePixelMap(this.previewPixelMap)
    }
    this.selectedUri = ''
    this.previewPixelMap = null
    this.cropRect = null
    this.releaseCroppedPreview()
    this.recommendation = null
    this.recommendationError = ''
    this.customGridWidthText = ''
    this.customGridHeightText = ''
    this.selectedPresetIndex = -1
    this.isCustomSizeSelected = false
    this.errorMsg = ''
    this.isLoading = false
    this.clearGeneratedPreview()
  }

  private clearGeneratedPreview(): void {
    this.activeExportTaskId = ++this.exportTaskSequence
    this.isExportingPng = false
    this.exportFeedback = ''
    this.generatedProject = null
    this.previewColorByCode = new Map<string, string>()
    this.patternStatistics = null
    this.isShowingGeneratedPreview = false
    this.conversionProgress = 0
    this.conversionCompletedRows = 0
    this.conversionTotalRows = 0
    PatternSession.clear()
  }

  private isCurrentRequest(requestGeneration: number): boolean {
    return this.isActive && requestGeneration === this.requestGeneration
  }

  private isCurrentGenerationTask(taskId: number): boolean {
    return this.isActive && this.activeGenerationTaskId === taskId
  }

  private isCurrentExportTask(taskId: number, project: Project): boolean {
    return this.isActive && this.activeExportTaskId === taskId &&
      this.generatedProject === project
  }

  private invalidateGenerationTask(): void {
    if (this.cancellationToken !== null) {
      this.cancellationToken.cancel()
      this.cancellationToken = null
    }
    this.activeGenerationTaskId = ++this.generationTaskSequence
    this.isGenerating = false
  }

  /**
   * 根据当前 cropRect 生成剪裁后的展示图（仅用于预览显示，不修改原 PixelMap）。
   * cropRect 为 null 时清空展示图，预览回退显示原图。
   */
  async refreshCroppedPreview(): Promise<void> {
    const source: image.PixelMap | null = this.previewPixelMap
    const crop: CropRect | null = this.cropRect
    if (source === null || crop === null) {
      this.releaseCroppedPreview()
      return
    }
    try {
      const info = await source.getImageInfo()
      const sourceWidth: number = info.size.width
      const sourceHeight: number = info.size.height
      // 防御性钳制（confirmCrop 写入时已钳制过）
      const cropX: number = Math.min(Math.max(0, crop.x), sourceWidth - 1)
      const cropY: number = Math.min(Math.max(0, crop.y), sourceHeight - 1)
      const cropWidth: number = Math.min(crop.width, sourceWidth - cropX)
      const cropHeight: number = Math.min(crop.height, sourceHeight - cropY)
      const sourceStride: number = source.getBytesNumberPerRow()
      const stagedBuffer: ArrayBuffer = new ArrayBuffer(sourceStride * cropHeight)
      const readArea: image.PositionArea = {
        pixels: stagedBuffer,
        offset: 0,
        stride: sourceStride,
        region: { x: cropX, y: cropY, size: { width: cropWidth, height: cropHeight } }
      }
      await source.readPixels(readArea)

      // writePixels 需要逐行紧凑排列（stride 可为 cropWidth*4），而读取缓冲区按源图跨距摆放，逐行拷贝
      const tightBuffer: ArrayBuffer = new ArrayBuffer(cropWidth * cropHeight * 4)
      const stagedBytes: Uint8Array = new Uint8Array(stagedBuffer)
      const tightBytes: Uint8Array = new Uint8Array(tightBuffer)
      for (let row: number = 0; row < cropHeight; row++) {
        const from: number = row * sourceStride
        const to: number = row * cropWidth * 4
        for (let i: number = 0; i < cropWidth * 4; i++) {
          tightBytes[to + i] = stagedBytes[from + i]
        }
      }

      const cropped: image.PixelMap = image.createPixelMapSync({
        size: { width: cropWidth, height: cropHeight },
        pixelFormat: image.PixelMapFormat.BGRA_8888,
        alphaType: info.alphaType,
        editable: true
      })
      const writeArea: image.PositionArea = {
        pixels: tightBuffer,
        offset: 0,
        stride: cropWidth * 4,
        region: { x: 0, y: 0, size: { width: cropWidth, height: cropHeight } }
      }
      await cropped.writePixels(writeArea)

      const previous: image.PixelMap | null = this.croppedPreviewPixelMap
      this.croppedPreviewPixelMap = cropped
      if (previous !== null) {
        this.releasePixelMap(previous)
      }
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      this.errorMsg = '生成剪裁预览失败：' + message
    }
  }

  /** 释放并清空剪裁展示图 */
  releaseCroppedPreview(): void {
    const previous: image.PixelMap | null = this.croppedPreviewPixelMap
    this.croppedPreviewPixelMap = null
    if (previous !== null) {
      this.releasePixelMap(previous)
    }
  }

  /** 图纸风格序号 → 采样模式（顺序与页面按钮一致） */
  private styleToSamplingMode(styleIndex: number): ImageSamplingMode {
    if (styleIndex === 1) {
      return ImageSamplingMode.ANIME_MODE
    }
    if (styleIndex === 2) {
      return ImageSamplingMode.LINE_ART_MODE
    }
    return ImageSamplingMode.PHOTO_AVERAGE
  }

  private releasePixelMap(pixelMap: image.PixelMap): void {
    pixelMap.release().catch((err: Error) => {
      console.error('释放图片资源失败: ' + err.message)
    })
  }

  private getCustomDimension(value: string): number {
    if (!/^\d+$/.test(value)) {
      return 0
    }
    const dimension: number = Number(value)
    return Number.isInteger(dimension) &&
      dimension >= GRID_MIN_SIZE && dimension <= GRID_MAX_SIZE
      ? dimension : 0
  }

  private isValidGridSize(gridWidth: number, gridHeight: number): boolean {
    return Number.isInteger(gridWidth) && gridWidth >= GRID_MIN_SIZE && gridWidth <= GRID_MAX_SIZE &&
      Number.isInteger(gridHeight) && gridHeight >= GRID_MIN_SIZE && gridHeight <= GRID_MAX_SIZE
  }

  private validateGeneratedCells(
    cells: GridCell[][],
    gridWidth: number,
    gridHeight: number
  ): void {
    if (cells.length !== gridHeight) {
      throw new Error('生成图纸的行数与目标尺寸不一致')
    }
    for (let row: number = 0; row < gridHeight; row++) {
      if (cells[row].length !== gridWidth) {
        throw new Error(`生成图纸第 ${row + 1} 行的列数与目标尺寸不一致`)
      }
    }
  }

  private createPreviewColorMap(colors: PatternColorCount[]): Map<string, string> {
    const colorByCode: Map<string, string> = new Map<string, string>()
    for (let colorIndex: number = 0; colorIndex < colors.length; colorIndex++) {
      colorByCode.set(colors[colorIndex].code, colors[colorIndex].hexColor)
    }
    return colorByCode
  }

  private createGeneratedId(prefix: string): string {
    ImageImportViewModel.generatedIdSequence++
    return `${prefix}_${Date.now()}_${ImageImportViewModel.generatedIdSequence}`
  }

  private async releaseOwnedPixelMap(pixelMap: image.PixelMap): Promise<boolean> {
    try {
      await pixelMap.release()
      return true
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      console.error('释放图纸生成图片资源失败：' + message)
      return false
    }
  }

  get hasImage(): boolean {
    return this.previewPixelMap !== null && this.selectedUri !== ''
  }
}

class ImageImportProgressListener implements ImageProcessingProgressListener {
  private viewModel: ImageImportViewModel
  private taskId: number

  constructor(viewModel: ImageImportViewModel, taskId: number) {
    this.viewModel = viewModel
    this.taskId = taskId
  }

  onProgress(completedRows: number, totalRows: number): void {
    this.viewModel.updateProgressForTask(this.taskId, completedRows, totalRows)
  }
}
