# CLAUDE.md — AI Bead Studio 项目开发规范

> **重要**：每次生成代码、修改代码、重构代码之前，必须先阅读本文件。

---

## 1. 项目介绍

**AI Bead Studio（AI拼豆图纸生成器）** 是一款 HarmonyOS NEXT 原生应用。

**当前版本目标**：
1. 图片导入与尺寸设置 → MARD 221 色拼豆图纸生成
2. 静态图纸预览、实际色号图例与材料统计
3. 独立 PNG 图纸导出

**暂缓范围**：完整图纸编辑器（逐格编辑、工具栏、撤销/重做、缩放/平移手势）不属于当前版本。AI 创作与社区属于后续方向。

**目标用户**：拼豆手工爱好者
**质量标准**：可发布至 HarmonyOS 应用市场的专业级应用

---

## 2. 开发环境

| 项目 | 版本/说明 |
|------|-----------|
| IDE | DevEco Studio (最新稳定版) |
| 操作系统 | Windows 11 |
| SDK | HarmonyOS NEXT SDK 6.1.1 (API 24) |
| 应用模型 | Stage 模型 |
| 开发语言 | ArkTS |
| UI 框架 | ArkUI（声明式） |
| 构建工具 | Hvigor |
| 包管理 | ohpm |
| 版本管理 | Git |

---

## 3. SDK 版本限制（强制）

- **唯一目标**：HarmonyOS NEXT SDK 6.1.1（API 24）
- **绝对禁止**：使用任何非 API 24 的 API，或从其他版本 SDK 示例代码中复制
- **API 验证**：任何 API 使用前，必须查阅 `docs/REFERENCES.md` 中的官方文档
- **不确定时**：停止实现，报告原因，等待确认
- **禁止猜测**：不允许凭记忆或训练数据猜测任何 API

---

## 4. MVVM 架构规范

```
View (ArkUI @Component)
  ↓ 单向依赖：调用 ViewModel 方法，读取 @State 状态
ViewModel (@Observed class)
  ↓ 单向依赖：调用 Service 方法，读写 Model 数据
Service (单例，纯 TypeScript)
  ↓ 单向依赖：操作数据
Model (纯数据类)
```

**核心规则**：
- **View**：渲染 UI、绑定状态、转发用户事件。不包含任何业务逻辑。不直接访问 Model 或 Service
- **ViewModel**：持有 UI 状态属性、编排业务逻辑、调用 Service。不导入任何 ArkUI 类型
- **Service**：单例模式（`static getInstance()`），纯计算/IO 操作。不导入 ViewModel 或 ArkUI 类型
- **Model**：纯数据类。不含业务逻辑
- **Utils**：纯函数工具，无状态，不依赖任何层

---

## 5. 项目目录结构

```
entry/src/main/ets/
├── entryability/          应用入口
│   └── EntryAbility.ets
├── entrybackupability/    备份扩展
│   └── EntryBackupAbility.ets
├── pages/                 页面层（路由入口）
│   ├── Index.ets          闪屏页
│   ├── MainPage.ets       主页（4Tab容器）
│   ├── home/              Tab1 首页
│   │   └── HomePage.ets
│   ├── creator/           Tab2 创作
│   │   ├── CreatorPage.ets
│   │   ├── AICreatePage.ets
│   │   ├── ImageImportPage.ets
│   │   └── PatternEditorPage.ets
│   ├── community/         Tab3 广场
│   │   ├── SquarePage.ets
│   │   ├── WorkDetailPage.ets
│   │   └── UserProfilePage.ets
│   ├── mine/              Tab4 我的
│   │   ├── MinePage.ets
│   │   ├── MyWorksPage.ets
│   │   └── MyFavoritesPage.ets
│   └── settings/          设置
│       └── SettingsPage.ets
├── model/                 数据模型层
├── viewmodel/             视图模型层
├── view/                  视图组件层
│   ├── components/        业务组件
│   └── common/            通用组件
├── service/               服务层
├── utils/                 工具层
│   └── Constants.ets      全局常量
└── data/palettes/         预设调色板数据
```

---

## 6. ArkTS 编码规范

### 6.1 类型定义
- **禁止**使用对象字面量作为类型声明（如 `Array<{a: string}>`）
- **必须**使用显式 `interface` 或 `class` 定义复杂类型
- **禁止**使用 `any` 类型
- **推荐**使用 `const` 声明常量，`let` 声明变量，禁止 `var`

### 6.2 装饰器使用
- `@Entry` —— 仅用于注册在 `main_pages.json` 中的独立路由页面
- `@Component` —— 所有 ArkUI 组件必须使用
- `@State` —— 组件内部状态，**变量名不能与 ArkUI 内置属性重名**
- `@Prop` —— 父传子单向数据流
- `@Link` —— 父传子双向绑定
- `@ObjectLink` —— 配合 `@Observed` 类使用，深层监听
- `@Provide/@Consume` —— 跨层级传递（如主题、用户信息）
- `@Builder` —— 可复用的 UI 构建函数
- `@Observed` —— ViewModel / Model 类装饰器。使用 `@ObjectLink` 在 View 中引用时，类属性变化自动触发 UI 更新

### 6.3 禁止的变量名（与 ArkUI 内置属性冲突）
`width` `height` `size` `color` `fontColor` `backgroundColor` `margin` `padding`
`border` `opacity` `visibility` `enabled` `scale` `rotate` `translate`
`fontSize` `fontWeight` `fontStyle` `text` `title` `label` `id` `key`
`index` `offset` `selected` `checked` `value` `min` `max` `background`
`foreground` `shadow` `blur` `flex` `align` `justify` `position` `layout`
`image` `icon`

### 6.4 资源引用
- 颜色：`$r('app.color.xxx')` —— 自动适配深浅色模式
- 字符串：`$r('app.string.xxx')` —— 支持未来多语言
- 禁止在代码中硬编码颜色值（如 `'#FFFFFF'`）或字符串

---

## 7. 专业级 UI 设计规范

> 设计目标：达到可发布至 HarmonyOS 应用市场的视觉质量。
> 参考产品：Procreate、Pixel Studio、Figma、剪映。

### 7.1 设计原则
- **当前页面**：仅用于功能验证，不作为最终 UI
- **新开发页面**：必须严格遵循本规范
- **视觉统一**：颜色、圆角、阴影、字体、间距全应用一致
- **不出现**：Phase、测试、Demo、占位等开发过程文字

### 7.2 布局规范
- **卡片式布局**：核心操作入口使用卡片承载，带圆角和阴影
- **信息层级**：标题 → 核心操作 → 辅助信息，层层递进
- **留白呼吸**：组件间距 ≥ 12vp，页面边距 16-20vp
- **操作入口突出**：主操作按钮使用主题色填充，次要操作用描边

### 7.3 颜色语义
- `color_primary` —— 主色调（品牌色），用于主按钮、选中态
- `color_secondary` —— 辅色调，用于次按钮、标签
- `color_accent` —— 强调色，用于高亮、角标
- `color_bg_primary` —— 主背景
- `color_bg_card` —— 卡片/浮层背景
- `color_bg_surface` —— 次级背景
- `color_text_primary` —— 主文字（标题）
- `color_text_secondary` —— 辅助文字（描述）
- `color_text_hint` —— 提示/占位文字
- `color_border` —— 边框
- `color_divider` —— 分割线
- `color_success / warning / error` —— 状态反馈色

### 7.4 深浅色模式
- 所有颜色必须通过 `$r('app.color.xxx')` 引用
- `base/element/color.json` 定义浅色值
- `dark/element/color.json` 定义深色值（一一对应）
- 深色模式下：背景加深、卡片用深灰、文字用浅色、降低对比度

### 7.5 视觉参数规范

| 参数 | 值 | 用途 |
|------|-----|------|
| 卡片圆角 | 12vp | 操作卡片、列表项 |
| 按钮圆角 | 8vp | 操作按钮 |
| 大圆角 | 20vp | 底部弹窗、面板 |
| 圆形 | 50% | 头像、颜色色块 |
| 卡片阴影 | offset(0,2) radius(8) #18000000 | 浮层感 |
| 按钮阴影 | offset(0,4) radius(12) #20000000 | 悬浮按钮 |
| 页面边距 | 16-20vp | 页面内容区 |
| 标题字号 | 28fp Bold | 页面大标题 |
| 段落字号 | 16fp Regular | 正文 |
| 辅助字号 | 13fp Regular | 描述文字 |
| 提示字号 | 11fp Regular | 角标、标注 |

### 7.6 图标规范
- **首选**：HarmonyOS SymbolGlyph 系统图标（需验证 API 24 支持）
- **备选**：统一风格的自定义 SVG 图标（放入 resources/base/media/）
- **兜底**：Unicode/Emoji（仅开发期临时使用）
- **风格要求**：线框风格（未选中）/ 填充风格（选中），统一 24vp

### 7.7 动画规范
- **页面切换**：淡入淡出 200ms，或右滑进入 250ms
- **按钮点击**：轻微缩放（1.0 → 0.97 → 1.0），150ms
- **列表加载**：骨架屏/淡入，300ms
- **Tab 切换**：200ms
- **加载状态**：旋转动画 + 文字提示
- **避免**：过于花哨或超过 500ms 的动画

### 7.8 适配规范
- 以 390vp（iPhone 14 逻辑宽度）为基准设计
- 内容区最大宽度 600vp（平板兼容）
- 使用 Flex 弹性布局 + 百分比 + layoutWeight
- 字号使用 fp 单位（跟随系统字体缩放）

---

## 8. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 页面文件 | PascalCase + Page 后缀 | `HomePage.ets` |
| 组件文件 | PascalCase | `BeadGrid.ets` |
| Model 文件 | PascalCase | `BeadPattern.ets` |
| ViewModel 文件 | PascalCase + ViewModel 后缀 | `EditorViewModel.ets` |
| Service 文件 | PascalCase + Service 后缀 | `ImageProcessingService.ets` |
| Utils 文件 | PascalCase | `ColorMatcher.ets` |
| 接口/类型 | PascalCase | `TabItemData` |
| 枚举 | PascalCase | `ToolType` |
| 常量 | UPPER_SNAKE_CASE | `PEGBOARD_DEFAULT` |
| 变量/函数 | camelCase | `currentTabIndex` |
| 私有成员 | 不加前缀，用 private | `private tabItems` |

---

## 9. 页面规范

### 9.1 路由页面规则
- 每个路由页面 **有且仅有** 一个 `@Entry` 装饰的组件
- 路由页面必须在 `main_pages.json` 中注册
- Tab 内嵌的子页面（直接 import 使用的）**不需要** `@Entry`，**不需要**注册路由

### 9.2 页面结构模板
```typescript
/**
 * PageName.ets - 页面功能简述
 */
@Entry
@Component
struct PageName {
  // 1. 状态变量
  @State viewModel: XxxViewModel = new XxxViewModel()

  // 2. 生命周期
  aboutToAppear(): void { }

  // 3. build
  build() {
    Column() {
      // UI 结构
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.color_bg_primary'))
  }

  // 4. @Builder 方法
  // 5. 其他私有方法
}
```

---

## 10. Service 规范

```typescript
/**
 * XxxService.ets - 服务功能简述
 */
export class XxxService {
  private static instance: XxxService | null = null

  static getInstance(): XxxService {
    if (!XxxService.instance) {
      XxxService.instance = new XxxService()
    }
    return XxxService.instance
  }

  // 业务方法使用 async/await 处理异步
  async doSomething(param: string): Promise<Result> {
    // 实现
  }
}
```

---

## 11. ViewModel 规范

```typescript
/**
 * XxxViewModel.ets - ViewModel 功能简述
 *
 * 【知识点】
 * @Observed 装饰类，使其属性变化能被 View 中的 @ObjectLink 感知。
 * ViewModel 中的属性不需要额外装饰器，直接用 class 属性即可。
 */
@Observed
export class XxxViewModel {
  // UI 状态属性（作为普通 class 属性，@Observed 类自动跟踪变化）
  isLoading: boolean = false
  data: SomeModel | null = null
  errorMsg: string = ''

  // 业务逻辑方法
  async loadData(): Promise<void> {
    this.isLoading = true
    try {
      // 调用 Service
      this.data = await SomeService.getInstance().fetch()
    } catch (err) {
      this.errorMsg = '加载失败'
    } finally {
      this.isLoading = false
    }
  }
}
```

---

## 12. Model 规范

```typescript
/**
 * SomeModel.ets - 模型功能简述
 *
 * Model 是纯数据类，不需要任何装饰器。
 * 当需要嵌套响应式时，可加 @Observed 配合 @ObjectLink 使用。
 */
export class SomeModel {
  id: string = ''
  name: string = ''
  createdAt: number = Date.now()

  constructor(id: string, name: string) {
    this.id = id
    this.name = name
  }
}
```

---

## 13. 异常处理规范

- **所有异步操作**必须包含 try-catch
- **异常必须有用户可见的错误提示**（通过 ViewModel 的 errorMsg 状态）
- **不允许静默失败**
- Service 层捕获后，应向上抛出有意义的错误信息
- 网络请求必须设置超时时间

```typescript
try {
  const result = await service.doSomething()
  // 处理成功
} catch (error) {
  console.error('操作失败: ' + error.message)
  this.errorMsg = '操作失败，请重试'
} finally {
  this.isLoading = false
}
```

---

## 14. 注释规范

- **所有 .ets 文件**头部必须有 JSDoc 注释，说明文件功能
- **class / interface / enum** 必须有注释说明用途
- **public 方法**必须有 `@param` 和 `@returns` 注释
- **复杂逻辑**必须有行内注释解释"为什么这样做"
- 注释语言：中文（面向中文开发者）
- 给初学者看的注释以 `【知识点】` 开头

---

## 15. 性能规范

- 网格渲染使用 Canvas，不允许用大量独立组件（100×100 = 10000 个组件会卡死）
- 大列表使用 LazyForEach 替代 ForEach
- 图片处理前先检查尺寸，超大图应先缩放
- 及时释放 PixelMap 等资源
- 避免在 build() 中执行复杂计算

---

## 16. 编译规范

- **每个 Phase 完成后**必须在 DevEco Studio 中编译通过
- **CompileArkTS 必须无错误**
- 编译命令：DevEco Studio → Build → Build HAP(s)
- 禁止提交编译失败的代码

---

## 17. Git 提交规范

- 提交信息格式：`<type>: <description>`
- type：`feat` `fix` `docs` `refactor` `style` `test` `chore`
- 示例：`feat: Phase 0 完成 4Tab 导航框架`

---

## 18. 开发阶段（Phase）

| Phase | 内容 | 状态 |
|-------|------|------|
| Phase 0 | 项目初始化与 4Tab 导航框架 | ✅ 已完成 |
| Phase 1 | 数据模型与调色板系统 | ✅ 已完成 |
| Phase 2 | 图片导入功能 | 🟡 代码完成，设备验证待完成 |
| Phase 3 | 图片转图纸、预览、材料统计与 PNG 导出 | 🟡 代码已完成；模拟器已验证统计总数与 PNG 保存/打开，逐色核对及真机验证待完成 |
| Phase 4 | 完整图纸编辑器 | ⏸️ 暂缓，不属于当前版本 |
| Phase 5 | AI 图片创作 | 🔴 后续方向 |
| Phase 6 | 项目管理与本地存储 | 🔴 待开始 |
| Phase 7 | 广场社区 | 🔴 待开始 |
| Phase 8 | 个人中心与设置 | 🔴 待开始 |
| Phase 9 | 打磨与发布优化 | 🔴 待开始 |

---

## 19. 输出规范

- **每次输出代码前**：先说明设计思路和方案选择
- **每次输出代码后**：列出修改的文件清单
- **每个 Phase 完成后**：
  1. 总结本阶段知识点
  2. 列出下一阶段目标
  3. 等待用户确认再继续
- **零基础友好**：解释关键概念，不跳步
- **不新增功能**：只修复时，不顺便添加/重构代码
- **不猜测 API**：不确定时停止并报告

---

## 20. 配套文档索引

本规范是项目开发的总纲，以下文档提供更详细的专项规范：

| 文档 | 路径 | 内容 |
|------|------|------|
| 项目总览 | `docs/PROJECT.md` | 项目信息、功能列表、技术栈 |
| 架构设计 | `docs/ARCHITECTURE.md` | 分层架构、状态管理、路由、存储 |
| 开发路线图 | `docs/ROADMAP.md` | 9 个 Phase 开发计划 |
| 设计系统 | `docs/UI_DESIGN.md` | 色彩、布局、组件、动画、图标规范 |
| 开发流程规范 | `docs/DEVELOPMENT_RULES.md` | 页面开发流程、禁止事项、审查清单 |
| 参考文档索引 | `docs/REFERENCES.md` | 官方 API 文档链接 + 已验证/不支持 API |
| 变更日志 | `docs/CHANGELOG.md` | 版本变更记录 |
| 任务看板 | `docs/TODO.md` | 当前阶段任务 + 已知问题 |
| 项目计划 | `C:\Users\12199\.claude\plans\zippy-plotting-valley.md` | 架构设计原始计划
