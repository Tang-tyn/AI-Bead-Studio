/**
 * PaletteTestPage.ets - MARD 221 色卡测试页面
 *
 * 【用途】
 * Phase 1 开发测试。验证数据加载和颜色匹配引擎。
 * 不是最终产品页面。
 */
import { PaletteTestViewModel, ColorDetail } from '../../viewmodel/PaletteTestViewModel'
import { BeadColor } from '../../model/BeadColor'

@Entry
@Component
struct PaletteTestPage {
  @State viewModel: PaletteTestViewModel = new PaletteTestViewModel()

  async aboutToAppear(): Promise<void> {
    try {
      // 获取 rawfile 内容（Promise 方式）
      const context = getContext(this)
      const resMgr = context.resourceManager
      const rawData: Uint8Array = await resMgr.getRawFileContent('palette/MardPalette.json')

      // Uint8Array → UTF-8 字符串
      let jsonText: string = ''
      for (let i = 0; i < rawData.length; i++) {
        jsonText += String.fromCharCode(rawData[i])
      }

      this.viewModel.initialize(jsonText)
    } catch (err) {
      let msg: string = '读取失败'
      if (err instanceof Error) {
        msg = `读取失败: ${err.message}`
      }
      this.viewModel.errorMsg = msg
      this.viewModel.isLoading = false
    }
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
      } else {
        this.buildContent()
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
      Text('MARD 221 色卡测试')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 48, bottom: 12 })
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
      Text('加载 MARD 221 色卡数据...')
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
          this.aboutToAppear()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /** 主内容 */
  @Builder
  buildContent(): void {
    Scroll() {
      Column() {
        // 颜色总数
        this.buildSummary()

        // 测试匹配区域
        this.buildTestSection()

        // 颜色网格
        this.buildColorGrid()
      }
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.TopStart)

    // 详情弹窗浮层
    if (this.viewModel.selectedColor !== null) {
      this.buildDetailOverlay(this.viewModel.selectedColor)
    }
  }

  /** 颜色总数摘要 */
  @Builder
  buildSummary(): void {
    Text(`共 ${this.viewModel.colorCount} 种颜色`)
      .fontSize(14)
      .fontColor($r('app.color.color_text_secondary'))
      .width('100%')
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  /** 测试匹配区域 */
  @Builder
  buildTestSection(): void {
    Column() {
      Text('Delta E 匹配测试')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_text_primary'))

      Text(`输入 RGB: [${this.viewModel.testRgb[0]}, ${this.viewModel.testRgb[1]}, ${this.viewModel.testRgb[2]}]`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 4 })

      Button('执行 Lab + Delta E 匹配')
        .fontSize(13)
        .margin({ top: 8 })
        .onClick(() => {
          this.viewModel.runTestMatch()
        })

      if (this.viewModel.testResult !== null) {
        Row() {
          // 结果色块
          Column()
            .width(40)
            .height(40)
            .borderRadius(4)
            .backgroundColor(this.viewModel.testResult.hex)
            .border({ width: 1, color: $r('app.color.color_border') })

          Column() {
            Text(`MARD 色号: ${this.viewModel.testResult.code}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.color_text_primary'))
            Text(`HEX: ${this.viewModel.testResult.hex}`)
              .fontSize(12)
              .fontColor($r('app.color.color_text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding(12)
        .margin({ top: 8 })
        .backgroundColor($r('app.color.color_bg_surface'))
        .borderRadius(8)
      }
    }
    .width('100%')
    .padding(16)
  }

  /** 颜色网格 */
  @Builder
  buildColorGrid(): void {
    Grid() {
      ForEach(this.viewModel.colors, (color: BeadColor, index: number) => {
        GridItem() {
          this.buildColorChip(color)
        }
      }, (color: BeadColor) => color.id)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .padding(16)
    .width('100%')
  }

  /** 单个颜色色块 */
  @Builder
  buildColorChip(color: BeadColor): void {
    Column() {
      // 颜色方块
      Column()
        .width('100%')
        .height(48)
        .borderRadius(6)
        .backgroundColor(color.hexColor)
        .border({ width: 1, color: $r('app.color.color_border') })

      // 色号
      Text(color.id)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // HEX
      Text(color.hexColor)
        .fontSize(10)
        .fontColor($r('app.color.color_text_hint'))
        .maxLines(1)
    }
    .width('100%')
    .padding(4)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(8)
    .onClick(() => {
      this.viewModel.selectColor(color)
    })
  }

  /** 颜色详情浮层 */
  @Builder
  buildDetailOverlay(detail: ColorDetail): void {
    Column() {
      // 遮罩
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#33000000')
    .position({ x: 0, y: 0 })
    .onClick(() => {
      this.viewModel.clearSelection()
    })

    Column() {
      // 颜色方块
      Column()
        .width(80)
        .height(80)
        .borderRadius(8)
        .backgroundColor(detail.hex)
        .border({ width: 2, color: $r('app.color.color_border') })

      // 色号
      Text(detail.code)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
        .margin({ top: 16 })

      // HEX
      Text(detail.hex)
        .fontSize(16)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 8 })

      // RGB
      Text(`RGB: ${detail.rgb}`)
        .fontSize(14)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 4 })

      // 关闭按钮
      Button('关闭')
        .fontSize(14)
        .margin({ top: 24 })
        .width(120)
        .onClick(() => {
          this.viewModel.clearSelection()
        })
    }
    .padding(32)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(16)
    .shadow({ radius: 24, color: '#28000000', offsetX: 0, offsetY: 8 })
    .position({ x: '50%', y: '50%' })
    .translate({ x: '-50%', y: '-50%' })
  }
}
