/**
 * CreatorPage.ets - 创作中心（AI创作 + 图片导入入口）
 *
 * 【功能介绍】
 * 创作页是用户创建拼豆图纸的起点，提供两条创作路径。
 *
 * 【当前阶段】
 * Phase 0 占位，Phase 1 测试入口。
 *
 * 【注意】此组件由 MainPage 直接嵌入，不是独立路由页面，不需要 @Entry。
 */
import { router } from '@kit.ArkUI'
import { ROUTE_PALETTE_TEST } from '../../utils/Constants'

@Component
export struct CreatorPage {
  build() {
    Column() {
      Text($r('app.string.page_create_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
        .width('100%')
        .padding({ left: 20, top: 48, bottom: 16 })
        .backgroundColor($r('app.color.color_bg_primary'))

      Column() {
        this.buildEntryCard(
          'AI 风格创作',
          '上传照片，AI帮你生成Q版、漫画风、像素风等风格化图片',
          '（Phase 5 实现）'
        )

        Blank().height(16)

        this.buildEntryCard(
          '照片转图纸',
          '从相册选择照片，自动像素化并匹配拼豆颜色',
          '（Phase 2 实现）'
        )

        // Phase 1 测试入口
        Button('MARD 221 色卡测试')
          .fontSize(13)
          .fontColor($r('app.color.color_text_hint'))
          .backgroundColor($r('app.color.color_bg_surface'))
          .margin({ top: 20 })
          .onClick(() => {
            router.pushUrl({ url: ROUTE_PALETTE_TEST })
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20, top: 16 })
      .backgroundColor($r('app.color.color_bg_primary'))
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildEntryCard(title: string, desc: string, badge: string): void {
    Row() {
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
          .margin({ bottom: 6 })

        Text(desc)
          .fontSize(13)
          .fontColor($r('app.color.color_text_secondary'))
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(badge)
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
          .margin({ top: 8 })
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .border({ width: 1, color: $r('app.color.color_primary'), radius: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(24)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .shadow({ radius: 8, color: '#18000000', offsetX: 0, offsetY: 2 })
  }
}
