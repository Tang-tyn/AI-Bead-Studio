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

  /** 图纸风格选择器：照片（区域平均） / 线条图（众数量化色） */
  @Builder
  buildStyleSelector(): void {
    Column() {
      Text('图纸风格')
        .fontSize(13)
        .fontColor($r('app.color.color_text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Button('照片 · 过渡自然')
          .fontSize(13)
          .fontColor(!this.viewModel.lineArtMode
            ? Color.White
            : $r('app.color.color_text_primary'))
          .backgroundColor(!this.viewModel.lineArtMode
            ? $r('app.color.color_primary')
            : $r('app.color.color_bg_surface'))
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onClick(() => {
            this.viewModel.lineArtMode = false
          })

        Blank().width(12)

        Button('线条图 · 轮廓清晰')
          .fontSize(13)
          .fontColor(this.viewModel.lineArtMode
            ? Color.White
            : $r('app.color.color_text_primary'))
          .backgroundColor(this.viewModel.lineArtMode
            ? $r('app.color.color_primary')
            : $r('app.color.color_bg_surface'))
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .layoutWeight(1)
          .onClick(() => {
            this.viewModel.lineArtMode = true
          })
      }
      .width('100%')
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
}
