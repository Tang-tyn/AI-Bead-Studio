/**
 * SquarePage.ets - 作品广场（社区Tab）
 *
 * 【功能介绍】
 * 广场是用户浏览、发现他人分享的拼豆作品的社区空间。
 *
 * 【当前阶段】
 * Phase 0 只显示占位内容。完整功能将在 Phase 7 实现。
 *
 * 【注意】此组件由 MainPage 直接嵌入，不是独立路由页面，不需要 @Entry。
 */
@Component
export struct SquarePage {
  build() {
    Column() {
      // ---- 顶部标题栏 ----
      Text($r('app.string.page_community_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
        .width('100%')
        .padding({ left: 20, top: 48, bottom: 16 })
        .backgroundColor($r('app.color.color_bg_primary'))

      // ---- 占位内容区域 ----
      Column() {
        // 空状态图标：使用emoji代替SymbolGlyph
        Text('👥')
          .fontSize(64)
          .margin({ bottom: 16 })

        // 提示文字
        Text($r('app.string.msg_empty_works'))
          .fontSize(16)
          .fontColor($r('app.color.color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('80%')
          .margin({ bottom: 8 })

        Text('（社区广场功能将在 Phase 7 实现）')
          .fontSize(12)
          .fontColor($r('app.color.color_text_hint'))

        // 功能预告标签
        Row() {
          this.buildFeatureChip('🏷️ 标签分类')
          this.buildFeatureChip('❤️ 点赞')
          this.buildFeatureChip('⭐ 收藏')
          this.buildFeatureChip('💬 评论')
        }
        .margin({ top: 24 })
        .width('80%')
        .justifyContent(FlexAlign.SpaceEvenly)
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

  /**
   * 构建一个功能预告标签
   */
  @Builder
  buildFeatureChip(text: string): void {
    Text(text)
      .fontSize(11)
      .fontColor($r('app.color.color_text_secondary'))
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .border({
        width: 1,
        color: $r('app.color.color_border'),
        radius: 12
      })
  }
}
