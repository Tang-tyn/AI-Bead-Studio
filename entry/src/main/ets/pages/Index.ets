/**
 * Index.ets - 启动闪屏页
 *
 * 【知识点】
 * 1. @Entry 装饰器：标记一个组件为页面入口（可被路由加载）
 * 2. @Component 装饰器：定义一个自定义组件
 * 3. @State 装饰器：组件内部状态变量，变化时自动触发UI重新渲染
 * 4. aboutToAppear()：组件生命周期方法，在组件即将显示时调用
 * 5. setTimeout：定时器，延迟执行代码
 * 6. router：页面路由模块，用于页面跳转
 *
 * 【设计思路】
 * 闪屏页的作用：
 * - 给用户展示品牌Logo和名称，建立品牌认知
 * - 在后台完成一些初始化工作（这里用延迟模拟）
 * - 提供流畅的启动过渡动画体验
 *
 * 为什么用 replaceUrl 而不是 pushUrl？
 * replaceUrl 会替换当前页面栈，用户按返回键时不会回到闪屏页。
 * pushUrl 会将新页面压入栈中，用户按返回键会回到闪屏页（这不是我们想要的）。
 */
import { router } from '@kit.ArkUI'
import { APP_NAME, APP_VERSION, ROUTE_MAIN } from '../utils/Constants'

@Entry
@Component
struct Index {
  // @State 装饰的变量：当值改变时，UI自动更新
  @State textOpacity: number = 0 // 控制文字淡入动画的透明度
  @State scaleValue: number = 0.8 // 控制Logo缩放动画

  /**
   * aboutToAppear() - 组件即将显示时的生命周期回调
   * 在这里启动动画和跳转定时器
   */
  aboutToAppear(): void {
    // 启动入场动画：延迟50ms后开始，让页面先渲染完成
    setTimeout(() => {
      this.textOpacity = 1 // 文字淡入到完全显示
      this.scaleValue = 1 // Logo缩放到正常大小
    }, 50)

    // 1.5秒后自动跳转到主页
    // 使用 replaceUrl 替代 pushUrl，这样用户按返回键不会回到闪屏页
    setTimeout(() => {
      router.replaceUrl({
        url: ROUTE_MAIN // 目标页面路径
      }).catch((err: Error) => {
        // 跳转失败时的错误处理
        console.error('Failed to navigate to MainPage: ' + err.message)
      })
    }, 1500)
  }

  build() {
    // Column：垂直布局容器，子组件从上到下排列
    Column() {
      // ---- Logo 图标区域 ----
      Text('🧩') // 使用emoji作为临时Logo
        .fontSize(80) // 字体大小
        .scale({ x: this.scaleValue, y: this.scaleValue }) // 缩放动画
        // 入场动画的缓动函数：先快后慢（类似弹簧效果）
        .animation({
          duration: 800, // 动画持续800毫秒
          curve: Curve.EaseOut, // 缓出曲线（开始快，结束慢）
          playMode: PlayMode.Normal
        })

      // 间距：Logo和名称之间的空白
      Blank().height(24)

      // ---- 应用名称 ----
      Text(APP_NAME)
        .fontSize(36) // 大标题字号
        .fontWeight(FontWeight.Bold) // 加粗
        .fontColor($r('app.color.color_text_primary')) // 使用资源引用（自动适配深色模式）
        .opacity(this.textOpacity) // 透明度（0=完全透明, 1=完全不透明）
        .animation({
          duration: 600,
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal
        })

      Blank().height(12)

      // ---- 副标题 ----
      Text($r('app.string.app_subtitle'))
        .fontSize(16)
        .fontColor($r('app.color.color_text_secondary'))
        .opacity(this.textOpacity)
        .animation({
          duration: 600,
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal
        })

      Blank().height(48)

      // ---- 版本号 ----
      Text(`v${APP_VERSION}`)
        .fontSize(12)
        .fontColor($r('app.color.color_text_hint'))
        .opacity(this.textOpacity)
        .animation({
          duration: 600,
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal
        })
    }
    // 容器样式：占满整个屏幕，内容居中
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center) // 垂直居中
    .alignItems(HorizontalAlign.Center) // 水平居中
    // 背景色使用资源引用，深浅模式自动切换
    .backgroundColor($r('app.color.color_bg_primary'))
  }
}
