/**
 * HomePage.ets - 首页（项目列表）
 *
 * 【功能介绍】
 * 首页是用户打开App后看到的第一个Tab。
 * 它展示用户保存的所有拼豆项目，并提供"新建项目"的入口。
 *
 * 【当前阶段】
 * Phase 0 只搭建框架，显示占位内容。
 * 完整功能（项目列表/搜索/排序）将在 Phase 6 实现。
 *
 * 【注意】此组件由 MainPage 直接嵌入，不是独立路由页面，不需要 @Entry。
 */
@Component
export struct HomePage {
  build() {
    Column() {
      // ---- 顶部标题栏 ----
      Text($r('app.string.page_home_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
        .width('100%')
        .padding({ left: 20, top: 48, bottom: 16 })
        .backgroundColor($r('app.color.color_bg_primary'))

      // ---- 占位内容区域 ----
      Column() {
        // 空状态图标：使用emoji代替SymbolGlyph
        Text('📂')
          .fontSize(64)
          .margin({ bottom: 16 })

        // 提示文字
        Text($r('app.string.msg_empty_projects'))
          .fontSize(16)
          .fontColor($r('app.color.color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('80%')
          .margin({ bottom: 8 })

        Text('（项目列表功能将在 Phase 6 实现）')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.color_bg_primary'))
    }
    .width('100%')
    .height('100%')
  }
}
