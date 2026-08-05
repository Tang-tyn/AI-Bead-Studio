/**
 * CreatorPage.ets - 创作中心
 *
 * 【职责】所有新创作流程入口（AI创作 + 图片转图纸）
 * 【注意】MainPage 直接嵌入，不是独立路由页面
 */
import { router } from '@kit.ArkUI'
import { ROUTE_PALETTE_TEST, ROUTE_IMAGE_IMPORT } from '../../utils/Constants'

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
        // AI 创作卡片（Phase 5 启用 — 暂时无跳转）
        this.buildEntryCard(
          'AI 风格创作',
          '上传照片，AI帮你生成Q版、漫画风、像素风等风格化图片',
          '（Phase 5 实现）'
        )

        Blank().height(16)

        // 照片转图纸卡片 — Phase 2 已启用
        this.buildEntryCardWithRoute(
          '照片转图纸',
          '从相册选择照片，自动像素化并匹配拼豆颜色',
          ROUTE_IMAGE_IMPORT
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

  /** 卡片（无点击跳转） */
  @Builder
  buildEntryCard(title: string, desc: string, badge?: string): void {
    this.buildCardBody(title, desc, badge, '')
  }

  /** 卡片（有点击跳转） */
  @Builder
  buildEntryCardWithRoute(title: string, desc: string, route: string): void {
    this.buildCardBody(title, desc, undefined, route)
  }

  /** 卡片主体 */
  @Builder
  buildCardBody(title: string, desc: string, badge: string | undefined, route: string): void {
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

        if (badge !== undefined) {
          Text(badge)
            .fontSize(11)
            .fontColor($r('app.color.color_primary'))
            .margin({ top: 8 })
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .border({ width: 1, color: $r('app.color.color_primary'), radius: 4 })
        }
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
    .onClick(() => {
      if (route !== '') {
        router.pushUrl({ url: route })
      }
    })
  }
}
