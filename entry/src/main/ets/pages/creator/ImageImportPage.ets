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
 * "生成图纸" → ImportSession.current = result → Phase 3 PatternEditorPage
 */
import { router } from '@kit.ArkUI'
import { ImageImportViewModel } from '../../viewmodel/ImageImportViewModel'
import { ImportSession } from '../../utils/ImportSession'
import { ROUTE_EDITOR } from '../../utils/Constants'

/** 网格预设选项类型 */
interface PresetOption {
  label: string
  width: number
  height: number
}

@Entry
@Component
struct ImageImportPage {
  @State viewModel: ImageImportViewModel = new ImageImportViewModel()

  aboutToAppear(): void {
    // 页面启动时自动打开相册
    this.viewModel.pickAndLoadImage()
  }

  build() {
    Column() {
      // ---- 标题栏 ----
      this.buildTitleBar()

      // ---- 内容区 ----
      if (this.viewModel.isLoading) {
        this.buildLoading()
      } else if (this.viewModel.errorMsg !== '') {
        this.buildError()
      } else if (!this.viewModel.hasImage) {
        this.buildPlaceholder()
      } else {
        this.buildPreview()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_bg_primary'))
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
      // 图片预览
      Scroll() {
        Column() {
          if (this.viewModel.previewPixelMap !== null) {
            Image(this.viewModel.previewPixelMap)
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
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      // 底部配置 + 按钮区
      Column() {
        // 网格尺寸预设选择
        this.buildPresetSelector()

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
            .enabled(this.viewModel.hasImage)
            .onClick(() => {
              ImportSession.save(this.viewModel.buildImportData())
              router.pushUrl({ url: ROUTE_EDITOR })
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

  /** 网格预设尺寸选择器 */
  @Builder
  buildPresetSelector(): void {
    Column() {
      Text('网格尺寸')
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
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
            width: this.viewModel.selectedPresetIndex === index ? 1.5 : 1,
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
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 12 })
  }
}
