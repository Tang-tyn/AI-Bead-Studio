/**
 * CreatorPage.ets - 创作中心（AI创作 + 图片导入入口）
 *
 * 【功能介绍】
 * 创作页是用户创建拼豆图纸的起点，提供两条创作路径：
 * 1. AI创作：上传照片进行AI风格化（Q版/漫画/像素风等）
 * 2. 导入照片：直接从相册选择照片转换为拼豆图纸
 *
 * 【当前阶段】
 * Phase 0 只显示两个入口卡片（占位），点击暂不跳转。
 * AI创作功能在 Phase 5 实现，图片导入在 Phase 2 实现。
 *
 * 【注意】此组件由 MainPage 直接嵌入，不是独立路由页面，不需要 @Entry。
 */
@Component
export struct CreatorPage {
  build() {
    Column() {
      // ---- 顶部标题栏 ----
      Text($r('app.string.page_create_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
        .width('100%')
        .padding({ left: 20, top: 48, bottom: 16 })
        .backgroundColor($r('app.color.color_bg_primary'))

      // ---- 功能入口区域 ----
      Column() {
        // 入口卡片1：AI创作
        this.buildEntryCard(
          '🤖',
          'AI 风格创作',
          '上传照片，AI帮你生成Q版、漫画风、像素风等风格化图片，再转为拼豆图纸',
          '（Phase 5 实现）'
        )

        // 间距
        Blank().height(16)

        // 入口卡片2：导入照片
        this.buildEntryCard(
          '📷',
          '照片转图纸',
          '从相册选择照片，自动像素化并匹配拼豆颜色，直接生成拼豆图纸',
          '（Phase 2 实现）'
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20, top: 16 })
      .backgroundColor($r('app.color.color_bg_primary'))
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建一个功能入口卡片
   * @param emoji 卡片图标
   * @param title 卡片标题
   * @param desc 卡片描述
   * @param badge 角标文字
   */
  @Builder
  buildEntryCard(emoji: string, title: string, desc: string, badge: string): void {
    Row() {
      // 左侧：emoji图标
      Text(emoji)
        .fontSize(40)
        .margin({ right: 16 })

      // 中间：标题和描述
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

        // 角标
        Text(badge)
          .fontSize(11)
          .fontColor($r('app.color.color_primary'))
          .margin({ top: 8 })
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .border({
            width: 1,
            color: $r('app.color.color_primary'),
            radius: 4
          })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：箭头符号（使用Unicode字符代替SymbolGlyph）
      Text('›')
        .fontSize(24)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_bg_card'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#18000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}
