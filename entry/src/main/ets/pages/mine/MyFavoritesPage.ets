/**
 * MyFavoritesPage.ets - 我的收藏列表（占位，Phase 8 实现）
 */
@Entry
@Component
export struct MyFavoritesPage {
  build() {
    Column() {
      Text('我的收藏')
        .fontSize(24).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
      Text('此页面将在 Phase 8 实现')
        .fontSize(14).fontColor($r('app.color.color_text_hint'))
        .margin({ top: 8 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.color_bg_primary'))
  }
}
