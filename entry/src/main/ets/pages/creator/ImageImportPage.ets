/**
 * ImageImportPage.ets - 图片导入页
 *
 * 【职责】
 * 用户从相册选择照片 → 预览 → 配置网格尺寸 → 确认导入。
 * 确认后将 PixelMap + 配置传递给 Phase 3 图纸生成。
 *
 * 【入口】
 * CreatorPage "照片转图纸" → router.pushUrl(ROUTE_IMAGE_IMPORT)
 *
 * 【出口】
 * "生成图纸" → 消费 ImportSession → 生成并暂存内存项目
 */
import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { ImageImportViewModel } from '../../viewmodel/ImageImportViewModel'
import { ImportSession } from '../../utils/ImportSession'
import { BeadGrid } from '../../view/components/BeadGrid'
import { PatternColorCount } from '../../model/PatternStatistics'
import { CropRect } from '../../model/CropRect'

/** 网格预设选项类型 */
interface PresetOption {
  label: string
  width: number
  height: number
}

/** 剪裁比例预设选项 */
interface CropRatioOption {
  label: string
  /** 宽高比（宽/高）；null 表示自由比例 */
  ratio: number | null
}

/** 剪裁框最小边长（源图像素） */
const CROP_MIN_PX: number = 16
/** 剪裁编辑器图片显示区高度（vp） */
const CROP_AREA_HEIGHT: number = 360
/** 剪裁比例预设 */
const CROP_RATIOS: CropRatioOption[] = [
  { label: '自由', ratio: null },
  { label: '1:1', ratio: 1 },
  { label: '4:3', ratio: 4 / 3 },
  { label: '3:4', ratio: 3 / 4 }
]

@Entry
@Component
struct ImageImportPage {
  @State viewModel: ImageImportViewModel = new ImageImportViewModel()

  // ---- 剪裁编辑器状态（剪裁框使用源图像素坐标） ----
  @State isCropEditing: boolean = false
  @State cropBoxX: number = 0
  @State cropBoxY: number = 0
  @State cropBoxW: number = 0
  @State cropBoxH: number = 0
  @State cropImageW: number = 0
  @State cropImageH: number = 0
  @State cropAreaW: number = 0
  @State cropAreaH: number = 0
  @State cropRatioIndex: number = 0
  /** 手势开始时的剪裁框快照（手势更新期间以它为基准计算增量） */
  private cropGestureStartBox: CropRect | null = null

  aboutToAppear(): void {
    this.viewModel.setActive(true)
    ImportSession.clear()
    // 页面启动时自动打开相册
    this.viewModel.pickAndLoadImage()
  }

  aboutToDisappear(): void {
    this.viewModel.setActive(false)
    ImportSession.clear()
  }

  build() {
    Stack() {
      Column() {
        // ---- 标题栏 ----
        this.buildTitleBar()

        // ---- 内容区 ----
        if (this.viewModel.isGenerating) {
          this.buildGenerating()
        } else if (this.viewModel.isLoading) {
          this.buildLoading()
        } else if (this.viewModel.isShowingGeneratedPreview &&
          this.viewModel.generatedProject !== null) {
          this.buildGenerated()
        } else if (this.viewModel.hasImage) {
          this.buildPreview()
        } else if (this.viewModel.errorMsg !== '') {
          this.buildError()
        } else {
          this.buildPlaceholder()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_bg_primary'))

      // ---- 剪裁编辑器（同页覆盖层） ----
      if (this.isCropEditing) {
        this.buildCropEditor()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 标题栏 */
  @Builder
  buildTitleBar(): void {
    Row() {
      Button('← 返回')
        .fontSize(14)
        .fontColor($r('app.color.color_text_primary'))
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 返回前释放资源
          this.viewModel.resetImage()
          router.back()
        })

      Text('照片转图纸')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 16, top: 48, bottom: 12 })
    .backgroundColor($r('app.color.color_bg_primary'))
  }

  /** 加载态 */
  @Builder
  buildLoading(): void {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color($r('app.color.color_primary'))
      Text('正在加载图片...')
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /** 图纸转换进度 */
  @Builder
  buildGenerating(): void {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color($r('app.color.color_primary'))
      Text(`正在生成图纸 ${this.viewModel.conversionProgress}%`)
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .margin({ top: 12 })
      Text(`已处理 ${this.viewModel.conversionCompletedRows} / ${this.viewModel.conversionTotalRows} 行网格`)
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 6 })
      Button('取消生成')
        .margin({ top: 20 })
        .onClick(() => {
          this.viewModel.cancelGeneration()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /** 生成成功提示；项目目前仅暂存在内存中 */
  @Builder
  buildGenerated(): void {
    Column() {
      if (this.viewModel.generatedProject !== null) {
        Text('图纸草稿预览')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 8 })
        Text(`${this.viewModel.generatedProject.pattern.gridWidth} × ${this.viewModel.generatedProject.pattern.gridHeight} 格`)
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })

        Scroll() {
          Column() {
            BeadGrid({
              pattern: this.viewModel.generatedProject.pattern,
              colorByCode: this.viewModel.previewColorByCode
            })
              .width('100%')
            this.buildMaterialList()
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)

        if (this.viewModel.exportFeedback !== '') {
          Text(this.viewModel.exportFeedback)
            .fontSize(12)
            .fontColor(this.viewModel.exportFeedback.startsWith('PNG 导出失败')
              ? $r('app.color.color_error')
              : $r('app.color.color_text_secondary'))
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        }

        Text('静态预览；项目暂存在内存中，离开应用后不会保留')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

        Row() {
          Button('返回修改尺寸')
            .fontSize(15)
            .fontColor($r('app.color.color_primary'))
            .backgroundColor($r('app.color.color_bg_card'))
            .border({ width: 1, color: $r('app.color.color_primary'), radius: 8 })
            .layoutWeight(1)
            .onClick(() => {
              this.viewModel.returnToImageSettings()
            })
          Blank().width(12)
          Button(this.viewModel.isExportingPng ? '正在保存…' : '保存到图库')
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_primary'))
            .borderRadius(8)
            .layoutWeight(1)
            .enabled(!this.viewModel.isExportingPng)
            .onClick(() => {
              const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
              this.viewModel.exportGeneratedPatternPng(context)
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 4 })
        Row() {
          Button('保存到指定位置')
            .fontSize(12)
            .fontColor($r('app.color.color_primary'))
            .backgroundColor(Color.Transparent)
            .enabled(!this.viewModel.isExportingPng)
            .onClick(() => {
              const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
              this.viewModel.exportGeneratedPatternPngToLocation(context)
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .padding({ left: 16, right: 16, bottom: 8 })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 显示本张图纸使用的 MARD 色号及材料数量。 */
  @Builder
  buildMaterialList(): void {
    if (this.viewModel.patternStatistics !== null) {
      Column() {
        Text('色号与材料统计')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
          .width('100%')
          .padding({ top: 20, bottom: 8 })

        Text(`共 ${this.viewModel.patternStatistics.totalBeads} 颗拼豆 · ${this.viewModel.patternStatistics.colors.length} 种颜色`)
          .fontSize(14)
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
          .padding({ bottom: 8 })

        if (this.viewModel.patternStatistics.invalidCellCount > 0) {
          Text(`${this.viewModel.patternStatistics.invalidCellCount} 个空缺或无效格未计入统计`)
            .fontSize(12)
            .fontColor($r('app.color.color_warning'))
            .width('100%')
            .padding({ bottom: 8 })
        }

        ForEach(
          this.viewModel.patternStatistics.colors,
          (entry: PatternColorCount) => {
            Row() {
              Column()
                .width(22)
                .height(22)
                .backgroundColor(entry.hexColor)
                .borderRadius(4)
                .border({ width: 1, color: $r('app.color.color_border'), radius: 4 })
              Text(entry.code)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.color_text_primary'))
                .margin({ left: 10 })
              Blank().layoutWeight(1)
              Text(`${entry.count} 颗`)
                .fontSize(14)
                .fontColor($r('app.color.color_text_secondary'))
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 4, right: 4 })
            .border({
              width: { bottom: 0.5 },
              color: $r('app.color.color_divider')
            })
          },
          (entry: PatternColorCount) => entry.code
        )
      }
      .width('100%')
      .padding({ top: 4, bottom: 16 })
    } else {
      Text('材料统计暂不可用')
        .fontSize(13)
        .fontColor($r('app.color.color_error'))
        .width('100%')
        .padding({ top: 16 })
    }
  }

  /** 错误态 */
  @Builder
  buildError(): void {
    Column() {
      Text(this.viewModel.errorMsg)
        .fontSize(16)
        .fontColor($r('app.color.color_error'))
      Button('重试')
        .margin({ top: 16 })
        .onClick(() => {
          this.viewModel.pickAndLoadImage()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /** 无图片时的占位引导 */
  @Builder
  buildPlaceholder(): void {
    Column() {
      Text('点击下方按钮选择一张照片')
        .fontSize(16)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ bottom: 24 })

      Button('选择照片')
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.color_primary'))
        .borderRadius(8)
        .padding({ left: 32, right: 32, top: 12, bottom: 12 })
        .onClick(() => {
          this.viewModel.pickAndLoadImage()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /** 图片预览 + 配置区 */
  @Builder
  buildPreview(): void {
    Column() {
      // 图片预览（已剪裁时展示剪裁结果；生成始终基于原图 + 剪裁区域采样）
      // 外层 Stack 让剪裁按钮悬浮在可视区域右下角，不随内容滚动
      Stack({ alignContent: Alignment.BottomEnd }) {
        Scroll() {
          Column() {
            if (this.viewModel.croppedPreviewPixelMap !== null ||
              this.viewModel.previewPixelMap !== null) {
              Image(this.viewModel.croppedPreviewPixelMap ?? this.viewModel.previewPixelMap)
                .width('100%')
                .objectFit(ImageFit.Contain)
                .backgroundColor($r('app.color.color_bg_surface'))
                .borderRadius(12)
            }
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .height('100%')
        .scrollable(ScrollDirection.Vertical)

        // 剪裁入口（固定于可视图片区域右下角，不随滚动移动）
        Button(this.viewModel.cropRect !== null ? '✂ 已剪裁' : '✂ 剪裁')
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('rgba(0, 0, 0, 0.55)')
          .borderRadius(16)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .margin(12)
          .onClick(() => {
            this.openCropEditor()
          })
      }
      .width('100%')
      .layoutWeight(1)

      // 底部配置 + 按钮区
      Column() {
        if (this.viewModel.errorMsg !== '') {
          Text(this.viewModel.errorMsg)
            .fontSize(12)
            .fontColor($r('app.color.color_error'))
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 8 })
        }

        // 网格尺寸预设选择
        this.buildPresetSelector()

        // 图纸风格选择（照片 / 线条图）
        this.buildStyleSelector()

        // 操作按钮行
        Row() {
          // 重新选择（取消时保留当前图片）
          Button('重新选择')
            .fontSize(14)
            .fontColor($r('app.color.color_primary'))
            .backgroundColor($r('app.color.color_bg_surface'))
            .border({ width: 1, color: $r('app.color.color_primary'), radius: 8 })
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .layoutWeight(1)
            .onClick(() => {
              this.viewModel.pickAndLoadImage()
            })

          Blank().width(16)

          // 生成图纸（无图片时禁用）
          Button('生成图纸 →')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.color_primary'))
            .borderRadius(8)
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .layoutWeight(1)
            .enabled(this.viewModel.hasImage && this.viewModel.isGridSizeValid)
            .onClick(() => {
              if (this.viewModel.isGenerating) {
                return
              }
              const importData = this.viewModel.takeImportData()
              if (importData === null) {
                this.viewModel.errorMsg = '请先选择一张图片'
                return
              }
              try {
                ImportSession.save(importData)
                const context = getContext(this)
                this.viewModel.generatePattern(context.resourceManager)
              } catch (err) {
                ImportSession.clear()
                const message: string = err instanceof Error ? err.message : '图纸生成失败，请重试'
                console.error('启动图纸生成失败：' + message)
                this.viewModel.errorMsg = message
              }
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 16 })
      .backgroundColor($r('app.color.color_bg_card'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 图纸风格选择器：照片（区域平均） / 动漫图（众数量化色） / 线条图（众数量化+暗线优先+色彩精简） */
  @Builder
  buildStyleSelector(): void {
    Column() {
      Text('图纸风格')
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Button('照片')
          .fontSize(13)
          .fontColor(this.viewModel.styleIndex === 0
            ? Color.White
            : $r('app.color.color_text_primary'))
          .backgroundColor(this.viewModel.styleIndex === 0
            ? $r('app.color.color_primary')
            : $r('app.color.color_bg_surface'))
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onClick(() => {
            this.viewModel.styleIndex = 0
          })

        Blank().width(8)

        Button('动漫图')
          .fontSize(13)
          .fontColor(this.viewModel.styleIndex === 1
            ? Color.White
            : $r('app.color.color_text_primary'))
          .backgroundColor(this.viewModel.styleIndex === 1
            ? $r('app.color.color_primary')
            : $r('app.color.color_bg_surface'))
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onClick(() => {
            this.viewModel.styleIndex = 1
          })

        Blank().width(8)

        Button('线条图')
          .fontSize(13)
          .fontColor(this.viewModel.styleIndex === 2
            ? Color.White
            : $r('app.color.color_text_primary'))
          .backgroundColor(this.viewModel.styleIndex === 2
            ? $r('app.color.color_primary')
            : $r('app.color.color_bg_surface'))
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onClick(() => {
            this.viewModel.styleIndex = 2
          })
      }
      .width('100%')

      Text('照片=真实照片过渡自然；动漫图=平涂色块干净、色彩全保留；线条图=白底黑线稿轮廓清晰')
        .fontSize(10)
        .fontColor($r('app.color.color_text_hint'))
        .width('100%')
        .margin({ top: 6 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  /** 网格预设尺寸选择器 */
  @Builder
  buildPresetSelector(): void {
    Column() {
      Text('图纸精细度')
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Column() {
          Text(this.viewModel.recommendation !== null
            ? `智能推荐 ${this.viewModel.recommendation.gridWidth} × ${this.viewModel.recommendation.gridHeight}`
            : '默认尺寸 58 × 58')
            .fontSize(14)
            .fontWeight(this.viewModel.selectedPresetIndex === -1 &&
              !this.viewModel.isCustomSizeSelected ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(this.viewModel.selectedPresetIndex === -1 &&
              !this.viewModel.isCustomSizeSelected
                ? $r('app.color.color_primary')
                : $r('app.color.color_text_primary'))
          Text(this.viewModel.recommendation !== null
            ? `细节${this.viewModel.recommendation.detailLevel} · 仅供参考，可手动调整`
            : this.viewModel.recommendationError !== ''
              ? this.viewModel.recommendationError
              : '分析后推荐合适尺寸')
            .fontSize(11)
            .fontColor($r('app.color.color_text_hint'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding(10)
        .backgroundColor($r('app.color.color_bg_surface'))
        .borderRadius(8)
        .border({
          width: this.viewModel.selectedPresetIndex === -1 &&
            !this.viewModel.isCustomSizeSelected ? 1.5 : 1,
          color: this.viewModel.selectedPresetIndex === -1 &&
            !this.viewModel.isCustomSizeSelected
              ? $r('app.color.color_primary')
              : $r('app.color.color_border'),
          radius: 8
        })
        .onClick(() => {
          this.viewModel.selectRecommendation()
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        ForEach(this.viewModel.presets, (preset: PresetOption, index: number) => {
          Column() {
            Text(preset.label)
              .fontSize(14)
              .fontWeight(
                this.viewModel.selectedPresetIndex === index
                  ? FontWeight.Bold : FontWeight.Regular
              )
              .fontColor(
                this.viewModel.selectedPresetIndex === index
                  ? $r('app.color.color_primary')
                  : $r('app.color.color_text_secondary')
              )
            // 成品尺寸提示：按标准 5mm 拼豆，1 格 = 0.5cm
            Text(`≈ ${(preset.width * 0.5).toFixed(1)} cm`)
              .fontSize(10)
              .fontColor($r('app.color.color_text_hint'))
              .margin({ top: 2 })
          }
          .width('30%')
          .padding({ top: 10, bottom: 10 })
          .backgroundColor(
            this.viewModel.selectedPresetIndex === index
              ? $r('app.color.color_bg_surface')
              : Color.Transparent
          )
          .borderRadius(8)
          .border({
            width: this.viewModel.selectedPresetIndex === index &&
              !this.viewModel.isCustomSizeSelected ? 1.5 : 1,
            color: this.viewModel.selectedPresetIndex === index
              ? $r('app.color.color_primary')
              : $r('app.color.color_border'),
            radius: 8
          })
          .onClick(() => {
            this.viewModel.selectPreset(index)
          })
        }, (preset: PresetOption, index: number) =>
          `${index}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // 当前所选尺寸的成品厘米提示（预设/推荐/自定义通用）
      Text(`成品约 ${(this.viewModel.gridWidth * 0.5).toFixed(1)} × ` +
        `${(this.viewModel.gridHeight * 0.5).toFixed(1)} cm（按 5mm 拼豆）`)
        .fontSize(11)
        .fontColor($r('app.color.color_text_hint'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })

      Row() {
        Text('自定义宽高')
          .fontSize(13)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
        Text(`${this.viewModel.gridWidth} × ${this.viewModel.gridHeight}`)
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })
      .onClick(() => {
        this.viewModel.selectCustomSize()
      })

      if (this.viewModel.isCustomSizeSelected) {
        Row() {
          TextInput({
            text: this.viewModel.customGridWidthText,
            placeholder: '宽度'
          })
            .type(InputType.Number)
            .width('44%')
            .padding(8)
            .backgroundColor($r('app.color.color_bg_surface'))
            .borderRadius(8)
            .onChange((value: string) => {
              this.viewModel.updateCustomGridWidth(value)
            })

          Text('×')
            .fontSize(14)
            .fontColor($r('app.color.color_text_secondary'))
            .width('12%')
            .textAlign(TextAlign.Center)

          TextInput({
            text: this.viewModel.customGridHeightText,
            placeholder: '高度'
          })
            .type(InputType.Number)
            .width('44%')
            .padding(8)
            .backgroundColor($r('app.color.color_bg_surface'))
            .borderRadius(8)
            .onChange((value: string) => {
              this.viewModel.updateCustomGridHeight(value)
            })
        }
        .width('100%')

        if (this.viewModel.customGridError !== '') {
          Text(this.viewModel.customGridError)
            .fontSize(11)
            .fontColor($r('app.color.color_error'))
            .width('100%')
            .margin({ top: 6 })
        }
      } else {
        Text('点此设置自定义宽高（10–200 格）')
          .fontSize(11)
          .fontColor($r('app.color.color_text_hint'))
          .width('100%')
          .margin({ top: 6 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 12 })
  }

  // ==================== 剪裁编辑器 ====================

  /** 剪裁编辑器覆盖层：原图 + 半透明遮罩 + 可拖动剪裁框 + 比例预设 */
  @Builder
  buildCropEditor(): void {
    Column() {
      // 标题栏
      Row() {
        Button('× 取消')
          .fontSize(14)
          .fontColor($r('app.color.color_text_primary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.isCropEditing = false
          })
        Text('剪裁图片')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(64)
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 48, bottom: 12 })

      // 图片 + 遮罩 + 剪裁框
      Stack() {
        if (this.viewModel.previewPixelMap !== null) {
          Image(this.viewModel.previewPixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }

        // 四周半透明遮罩（中间镂空出剪裁框）
        Column()
          .backgroundColor(Color.Black)
          .opacity(0.45)
          .position({
            x: this.cropOffsetX(),
            y: this.cropOffsetY()
          })
          .size({
            width: this.cropImageW * this.cropScale(),
            height: Math.max(0, this.cropBoxY * this.cropScale())
          })
        Column()
          .backgroundColor(Color.Black)
          .opacity(0.45)
          .position({
            x: this.cropOffsetX(),
            y: this.cropOffsetY() + this.cropBoxY * this.cropScale()
          })
          .size({
            width: Math.max(0, this.cropBoxX * this.cropScale()),
            height: Math.max(0, this.cropBoxH * this.cropScale())
          })
        Column()
          .backgroundColor(Color.Black)
          .opacity(0.45)
          .position({
            x: this.cropOffsetX() + (this.cropBoxX + this.cropBoxW) * this.cropScale(),
            y: this.cropOffsetY() + this.cropBoxY * this.cropScale()
          })
          .size({
            width: Math.max(0,
              (this.cropImageW - this.cropBoxX - this.cropBoxW) * this.cropScale()),
            height: Math.max(0, this.cropBoxH * this.cropScale())
          })
        Column()
          .backgroundColor(Color.Black)
          .opacity(0.45)
          .position({
            x: this.cropOffsetX(),
            y: this.cropOffsetY() + (this.cropBoxY + this.cropBoxH) * this.cropScale()
          })
          .size({
            width: this.cropImageW * this.cropScale(),
            height: Math.max(0,
              (this.cropImageH - this.cropBoxY - this.cropBoxH) * this.cropScale())
          })

        // 剪裁框（拖动整体移动）
        Column()
          .backgroundColor(Color.Transparent)
          .border({ width: 2, color: Color.White })
          .position({
            x: this.cropOffsetX() + this.cropBoxX * this.cropScale(),
            y: this.cropOffsetY() + this.cropBoxY * this.cropScale()
          })
          .size({
            width: this.cropBoxW * this.cropScale(),
            height: this.cropBoxH * this.cropScale()
          })
          .gesture(PanGesture()
            .onActionStart(() => {
              this.onCropGestureStart()
            })
            .onActionUpdate((event: GestureEvent) => {
              this.onCropMoveUpdate(event)
            }))

        // 四角拖拽手柄：0 左上 / 1 右上 / 2 左下 / 3 右下
        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(Color.White)
          .border({ width: 2, color: $r('app.color.color_primary') })
          .position({
            x: this.cropOffsetX() + this.cropBoxX * this.cropScale() - 10,
            y: this.cropOffsetY() + this.cropBoxY * this.cropScale() - 10
          })
          .gesture(PanGesture()
            .onActionStart(() => {
              this.onCropGestureStart()
            })
            .onActionUpdate((event: GestureEvent) => {
              this.onCropResizeUpdate(0, event)
            }))
        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(Color.White)
          .border({ width: 2, color: $r('app.color.color_primary') })
          .position({
            x: this.cropOffsetX() + (this.cropBoxX + this.cropBoxW) * this.cropScale() - 10,
            y: this.cropOffsetY() + this.cropBoxY * this.cropScale() - 10
          })
          .gesture(PanGesture()
            .onActionStart(() => {
              this.onCropGestureStart()
            })
            .onActionUpdate((event: GestureEvent) => {
              this.onCropResizeUpdate(1, event)
            }))
        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(Color.White)
          .border({ width: 2, color: $r('app.color.color_primary') })
          .position({
            x: this.cropOffsetX() + this.cropBoxX * this.cropScale() - 10,
            y: this.cropOffsetY() + (this.cropBoxY + this.cropBoxH) * this.cropScale() - 10
          })
          .gesture(PanGesture()
            .onActionStart(() => {
              this.onCropGestureStart()
            })
            .onActionUpdate((event: GestureEvent) => {
              this.onCropResizeUpdate(2, event)
            }))
        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(Color.White)
          .border({ width: 2, color: $r('app.color.color_primary') })
          .position({
            x: this.cropOffsetX() + (this.cropBoxX + this.cropBoxW) * this.cropScale() - 10,
            y: this.cropOffsetY() + (this.cropBoxY + this.cropBoxH) * this.cropScale() - 10
          })
          .gesture(PanGesture()
            .onActionStart(() => {
              this.onCropGestureStart()
            })
            .onActionUpdate((event: GestureEvent) => {
              this.onCropResizeUpdate(3, event)
            }))
      }
      .width('100%')
      .height(CROP_AREA_HEIGHT)
      .backgroundColor($r('app.color.color_bg_surface'))
      .onAreaChange((_oldArea: Area, newArea: Area) => {
        this.cropAreaW = Number(newArea.width)
        this.cropAreaH = Number(newArea.height)
      })

      // 比例预设
      Row() {
        ForEach(CROP_RATIOS, (option: CropRatioOption, index: number) => {
          Button(option.label)
            .fontSize(13)
            .fontColor(this.cropRatioIndex === index
              ? Color.White
              : $r('app.color.color_text_primary'))
            .backgroundColor(this.cropRatioIndex === index
              ? $r('app.color.color_primary')
              : $r('app.color.color_bg_surface'))
            .borderRadius(8)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
              this.cropApplyRatio(index)
            })
        }, (option: CropRatioOption) => option.label)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 16 })

      Blank()

      // 底部操作
      Row() {
        Button('重置')
          .fontSize(15)
          .fontColor($r('app.color.color_primary'))
          .backgroundColor($r('app.color.color_bg_card'))
          .border({ width: 1, color: $r('app.color.color_primary'), radius: 8 })
          .layoutWeight(1)
          .onClick(() => {
            this.cropResetBox()
          })
        Blank().width(16)
        Button('✓ 完成剪裁')
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.color_primary'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.confirmCrop()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_primary'))
  }

  /** 显示区缩放系数：源图像素 → 显示 vp */
  private cropScale(): number {
    if (this.cropImageW <= 0 || this.cropImageH <= 0 ||
      this.cropAreaW <= 0 || this.cropAreaH <= 0) {
      return 0
    }
    return Math.min(this.cropAreaW / this.cropImageW, this.cropAreaH / this.cropImageH)
  }

  /** 显示区内图片左上角的横向偏移（vp，Contain 留白） */
  private cropOffsetX(): number {
    return (this.cropAreaW - this.cropImageW * this.cropScale()) / 2
  }

  /** 显示区内图片左上角的纵向偏移（vp，Contain 留白） */
  private cropOffsetY(): number {
    return (this.cropAreaH - this.cropImageH * this.cropScale()) / 2
  }

  /** 打开剪裁编辑器：读取图片尺寸，按已有剪裁或整图初始化剪裁框 */
  private async openCropEditor(): Promise<void> {
    const pixelMap = this.viewModel.previewPixelMap
    if (pixelMap === null) {
      return
    }
    let imageWidth: number = 0
    let imageHeight: number = 0
    try {
      const info = await pixelMap.getImageInfo()
      imageWidth = info.size.width
      imageHeight = info.size.height
    } catch (err) {
      const message: string = err instanceof Error ? err.message : '未知错误'
      this.viewModel.errorMsg = '读取图片尺寸失败：' + message
      return
    }
    if (imageWidth < 1 || imageHeight < 1) {
      return
    }
    this.cropImageW = imageWidth
    this.cropImageH = imageHeight
    const existing: CropRect | null = this.viewModel.cropRect
    if (existing !== null) {
      this.cropBoxX = existing.x
      this.cropBoxY = existing.y
      this.cropBoxW = existing.width
      this.cropBoxH = existing.height
    } else {
      this.cropBoxX = 0
      this.cropBoxY = 0
      this.cropBoxW = imageWidth
      this.cropBoxH = imageHeight
    }
    this.isCropEditing = true
  }

  /** 确认剪裁：取整并写回 ViewModel，刷新剪裁展示图，关闭编辑器 */
  private confirmCrop(): void {
    const x: number = Math.max(0, Math.round(this.cropBoxX))
    const y: number = Math.max(0, Math.round(this.cropBoxY))
    const width: number = Math.max(1, Math.round(this.cropBoxW))
    const height: number = Math.max(1, Math.round(this.cropBoxH))

    // 框选即整图时视为未剪裁，预览回退原图
    if (x <= 0 && y <= 0 && width >= this.cropImageW && height >= this.cropImageH) {
      this.viewModel.cropRect = null
      this.viewModel.refreshCroppedPreview()
      this.isCropEditing = false
      return
    }

    const clampedX: number = Math.min(x, this.cropImageW - 1)
    const clampedY: number = Math.min(y, this.cropImageH - 1)
    this.viewModel.cropRect = new CropRect(
      clampedX,
      clampedY,
      Math.min(width, this.cropImageW - clampedX),
      Math.min(height, this.cropImageH - clampedY)
    )
    this.viewModel.refreshCroppedPreview()
    this.isCropEditing = false
  }

  /** 重置剪裁框为整张图 */
  private cropResetBox(): void {
    this.cropBoxX = 0
    this.cropBoxY = 0
    this.cropBoxW = this.cropImageW
    this.cropBoxH = this.cropImageH
    this.cropRatioIndex = 0
  }

  /** 应用比例预设：按比例收缩当前剪裁框（中心不变，只缩不放大） */
  private cropApplyRatio(index: number): void {
    this.cropRatioIndex = index
    const ratio: number | null = CROP_RATIOS[index].ratio
    if (ratio === null) {
      return
    }
    const centerX: number = this.cropBoxX + this.cropBoxW / 2
    const centerY: number = this.cropBoxY + this.cropBoxH / 2
    let newWidth: number = this.cropBoxW
    let newHeight: number = newWidth / ratio
    if (newHeight > this.cropBoxH) {
      newHeight = this.cropBoxH
      newWidth = newHeight * ratio
    }
    this.cropBoxX = Math.max(0, centerX - newWidth / 2)
    this.cropBoxY = Math.max(0, centerY - newHeight / 2)
    this.cropBoxW = newWidth
    this.cropBoxH = newHeight
  }

  /** 手势开始：记录剪裁框快照 */
  private onCropGestureStart(): void {
    this.cropGestureStartBox = new CropRect(
      this.cropBoxX, this.cropBoxY, this.cropBoxW, this.cropBoxH)
  }

  /** 整体拖动：平移剪裁框（钳制在图片范围内） */
  private onCropMoveUpdate(event: GestureEvent): void {
    const start: CropRect | null = this.cropGestureStartBox
    const scale: number = this.cropScale()
    if (start === null || scale <= 0) {
      return
    }
    const deltaX: number = event.offsetX / scale
    const deltaY: number = event.offsetY / scale
    this.cropBoxX = Math.min(
      this.cropImageW - start.width, Math.max(0, start.x + deltaX))
    this.cropBoxY = Math.min(
      this.cropImageH - start.height, Math.max(0, start.y + deltaY))
  }

  /**
   * 角点拖拽：0 左上 / 1 右上 / 2 左下 / 3 右下。
   * 对角固定为锚点，拖动角在图片范围内移动；锁定比例时按比例换算另一维。
   */
  private onCropResizeUpdate(corner: number, event: GestureEvent): void {
    const start: CropRect | null = this.cropGestureStartBox
    const scale: number = this.cropScale()
    if (start === null || scale <= 0) {
      return
    }
    const deltaX: number = event.offsetX / scale
    const deltaY: number = event.offsetY / scale
    const anchorRight: boolean = corner === 0 || corner === 2
    const anchorBottom: boolean = corner === 0 || corner === 1
    const anchorX: number = anchorRight ? start.x + start.width : start.x
    const anchorY: number = anchorBottom ? start.y + start.height : start.y
    let movingX: number = anchorRight ? start.x + deltaX : start.x + start.width + deltaX
    let movingY: number = anchorBottom ? start.y + deltaY : start.y + start.height + deltaY
    movingX = Math.min(this.cropImageW, Math.max(0, movingX))
    movingY = Math.min(this.cropImageH, Math.max(0, movingY))

    let newWidth: number = Math.abs(movingX - anchorX)
    let newHeight: number = Math.abs(movingY - anchorY)
    const ratio: number | null = CROP_RATIOS[this.cropRatioIndex].ratio
    if (ratio !== null) {
      const maxWidth: number = anchorRight ? anchorX : this.cropImageW - anchorX
      const maxHeight: number = anchorBottom ? anchorY : this.cropImageH - anchorY
      newWidth = Math.min(newWidth, maxWidth)
      newHeight = newWidth / ratio
      if (newHeight > maxHeight) {
        newHeight = maxHeight
        newWidth = newHeight * ratio
      }
    }
    if (newWidth < CROP_MIN_PX || newHeight < CROP_MIN_PX) {
      return
    }
    this.cropBoxX = anchorRight ? anchorX - newWidth : anchorX
    this.cropBoxY = anchorBottom ? anchorY - newHeight : anchorY
    this.cropBoxW = newWidth
    this.cropBoxH = newHeight
  }
}
