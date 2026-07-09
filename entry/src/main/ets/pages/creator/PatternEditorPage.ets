/**
 * PatternEditorPage.ets - 图纸编辑器页（占位，Phase 4 实现）
 */
@Entry
@Component
export struct PatternEditorPage {
  build() {
    Column() {
      Text('图纸编辑器')
        .fontSize(24).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
      Text('此页面将在 Phase 4 实现')
        .fontSize(14).fontColor($r('app.color.color_text_hint'))
        .margin({ top: 8 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.color_bg_primary'))
  }
}
