/**
 * SettingsPage.ets - 设置页（占位，Phase 8 实现）
 */
@Entry
@Component
export struct SettingsPage {
  build() {
    Column() {
      Text('设置')
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
