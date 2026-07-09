/**
 * MinePage.ets - 个人中心（我的Tab）
 *
 * 【功能介绍】
 * 个人中心是用户管理自己账号、作品、收藏和设置的地方。
 *
 * 【当前阶段】
 * Phase 0 只显示占位内容。完整功能将在 Phase 8 实现。
 *
 * 【注意】此组件由 MainPage 直接嵌入，不是独立路由页面，不需要 @Entry。
 */
@Component
export struct MinePage {
  build() {
    Column() {
      // ---- 顶部标题栏 ----
      Text($r('app.string.page_mine_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
        .width('100%')
        .padding({ left: 20, top: 48, bottom: 16 })
        .backgroundColor($r('app.color.color_bg_primary'))

      // ---- 占位内容区域 ----
      Column() {
        // 头像占位：使用emoji代替SymbolGlyph
        Column() {
          Text('👤')
            .fontSize(40)
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor($r('app.color.color_bg_surface'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 12 })

        // 昵称占位
        Text('拼豆爱好者')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
          .margin({ bottom: 24 })

        // 功能菜单占位
        this.buildMenuRow('📋', '我的作品', '（Phase 8 实现）')
        this.buildMenuRow('⭐', '我的收藏', '（Phase 8 实现）')
        this.buildMenuRow('⚙️', '设置', '（Phase 8 实现）')

        // 数据统计占位
        Row() {
          this.buildStatItem('0', '作品')
          this.buildStatItem('0', '收藏')
          this.buildStatItem('0', '获赞')
        }
        .width('80%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.color_bg_primary'))
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建菜单行（不使用SymbolGlyph箭头）
   */
  @Builder
  buildMenuRow(emoji: string, label: string, badge: string): void {
    Row() {
      Text(emoji).fontSize(20).margin({ right: 12 })
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.color_text_primary'))
        .layoutWeight(1)
      Text(badge)
        .fontSize(12)
        .fontColor($r('app.color.color_text_hint'))
      // 箭头使用Unicode字符
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.color_text_hint'))
    }
    .width('80%')
    .padding({ top: 16, bottom: 16, left: 16, right: 16 })
    .border({
      width: { bottom: 0.5 },
      color: $r('app.color.color_divider')
    })
  }

  /**
   * 构建统计数字项
   */
  @Builder
  buildStatItem(count: string, label: string): void {
    Column() {
      Text(count)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_text_primary'))
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.color_text_secondary'))
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
