/**
 * MainPage.ets - 主页面（4Tab底部导航容器）
 *
 * 【写给零基础学习者】
 * 这个页面是用户看到闪屏后进入的"主界面"。
 * 它本身不显示具体内容，只是一个"框架"，底部有4个按钮（Tab），
 * 点击不同按钮切换显示不同的子页面。
 *
 * 【Tabs组件】
 * 就像一本活页笔记本：
 * - Tabs 是笔记本的外壳
 * - TabContent 是每一页纸
 * - TabBar 是书签标签
 * - 用户点击不同的书签，翻到不同的内容页
 *
 * 【@State 装饰器】
 * 标记一个变量为"响应式状态"——变量值改变时，界面自动更新。
 * 这里用 @State 跟踪当前选中的Tab索引。
 */

// 导入4个Tab的内容页面（这些是直接嵌入的组件，不需要@Entry）
import { HomePage } from './home/HomePage'
import { CreatorPage } from './creator/CreatorPage'
import { SquarePage } from './community/SquarePage'
import { MinePage } from './mine/MinePage'

/**
 * TabItemData - 每个Tab的数据结构
 * 【知识点】
 * ArkTS严格模式要求使用显式 interface 定义复杂类型，
 * 不允许在变量声明中直接使用对象字面量类型 `{ a: string; b: string }`。
 */
interface TabItemData {
  title: ResourceStr    // Tab的文字标签（使用$r引用资源，支持多语言）
  icon: string          // Tab的图标（使用emoji字符）
}

@Entry
@Component
struct MainPage {
  // 当前选中的Tab索引，0=首页, 1=创作, 2=广场, 3=我的
  @State currentTabIndex: number = 0

  // Tab标题和图标数据
  // 使用 interface 定义类型，符合 ArkTS 严格模式要求
  private tabItems: Array<TabItemData> = [
    { title: $r('app.string.tab_home'), icon: '🏠' },
    { title: $r('app.string.tab_create'), icon: '✨' },
    { title: $r('app.string.tab_community'), icon: '🏘️' },
    { title: $r('app.string.tab_mine'), icon: '👤' }
  ]

  build() {
    // Tabs组件：底部导航栏的容器
    Tabs({
      barPosition: BarPosition.End,  // 导航栏放底部
      index: this.currentTabIndex    // 绑定当前选中的Tab
    }) {
      // ---- Tab 0: 首页 ----
      TabContent() {
        HomePage()
      }
      .tabBar(this.buildTabBar(0))

      // ---- Tab 1: 创作 ----
      TabContent() {
        CreatorPage()
      }
      .tabBar(this.buildTabBar(1))

      // ---- Tab 2: 广场 ----
      TabContent() {
        SquarePage()
      }
      .tabBar(this.buildTabBar(2))

      // ---- Tab 3: 我的 ----
      TabContent() {
        MinePage()
      }
      .tabBar(this.buildTabBar(3))
    }
    .width('100%')
    .height('100%')
    .barHeight(56)                    // 底部导航栏高度
    .animationDuration(200)          // Tab切换动画时长（毫秒）
    .onChange((index: number) => {
      // 当用户点击Tab时，更新当前索引
      this.currentTabIndex = index
    })
    .backgroundColor($r('app.color.color_bg_primary'))
  }

  /**
   * 构建单个Tab的底部标签样式
   * @param tabIndex Tab的索引
   *
   * 不使用 SymbolGlyph（SDK 6.1.1 部分图标不支持），
   * 改用 Text + emoji 作为图标，简单可靠。
   */
  @Builder
  buildTabBar(tabIndex: number): void {
    Column() {
      // Tab图标：使用emoji文字代替系统图标
      Text(this.tabItems[tabIndex].icon)
        .fontSize(24)

      // Tab文字标签
      Text(this.tabItems[tabIndex].title)
        .fontSize(10)
        .fontColor(
          this.currentTabIndex === tabIndex
            ? $r('app.color.tab_icon_selected')
            : $r('app.color.tab_icon_normal')
        )
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 4 })
  }
}
