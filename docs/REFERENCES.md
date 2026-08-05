# REFERENCES.md — 官方参考文档索引

> **强制规则**：任何 API 使用前，必须先查阅本文件中的对应官方文档。
> **禁止猜测**：不允许凭记忆或训练数据猜测任何 API。
> **文档优先**：如果发现文档与代码冲突，以官方文档为准。

---

## 一、核心开发文档（优先参考）

| 文档 | 链接 | 用途 |
|------|------|------|
| HarmonyOS Developer 官方首页 | https://developer.huawei.com/consumer/cn/ | 总入口，公告、最新动态 |
| HarmonyOS NEXT 开发文档 | https://developer.huawei.com/consumer/cn/doc/ | 开发指南、最佳实践 |
| ArkUI 开发指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview | ArkUI 组件、布局、动画 |
| ArkTS 语言参考 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-language-reference | ArkTS 语法、类型系统、装饰器 |
| API Reference | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ | 完整 API 索引和参数详情 |
| HarmonyOS Design | https://developer.huawei.com/consumer/cn/design/ | 设计规范、组件库、视觉指导 |
| 官方 Samples | https://developer.huawei.com/consumer/cn/doc/harmonyos-samples/ | 示例代码和学习项目 |

---

## 二、补充参考（仅作辅助理解，不作为 API 实现依据）

| 文档 | 链接 | 说明 |
|------|------|------|
| OpenHarmony 文档 | https://docs.openharmony.cn/ | 开源版本，部分 API 与 NEXT 不同 |
| Gitee OpenHarmony | https://gitee.com/openharmony/docs | 开源代码和文档 |

> ⚠️ OpenHarmony 和 HarmonyOS NEXT 存在差异，NEXT 独有的 API 不会出现在 OpenHarmony 中。
> OpenHarmony 文档仅用于理解概念和原理，**不作为 HarmonyOS NEXT API 的实现依据**。

---

## 三、常用模块快速导航

### 3.1 UI 组件（@ohos.arkui）

| 模块 | 用途 | 查询路径 |
|------|------|----------|
| Text | 文本显示 | API Reference → ArkUI → 基础组件 → Text |
| Image | 图片显示 | API Reference → ArkUI → 基础组件 → Image |
| Button | 按钮 | API Reference → ArkUI → 基础组件 → Button |
| List / ListItem | 列表 | API Reference → ArkUI → 容器组件 → List |
| Grid / GridItem | 网格 | API Reference → ArkUI → 容器组件 → Grid |
| Tabs / TabContent | 标签导航 | API Reference → ArkUI → 容器组件 → Tabs |
| Navigation | 页面导航栈 | API Reference → ArkUI → 导航 → Navigation |
| Canvas | 2D 绘制 | API Reference → ArkUI → 绘制组件 → Canvas |
| SymbolGlyph | 系统图标 | API Reference → ArkUI → 基础组件 → SymbolGlyph |
| WaterFlow | 瀑布流 | API Reference → ArkUI → 容器组件 → WaterFlow |

### 3.2 状态管理

| 模块 | 用途 | 查询路径 |
|------|------|----------|
| @State | 组件内状态 | ArkUI 指南 → 状态管理 → @State |
| @Prop | 父传子单向 | ArkUI 指南 → 状态管理 → @Prop |
| @Link | 父传子双向 | ArkUI 指南 → 状态管理 → @Link |
| @Observed | 类装饰器 | ArkUI 指南 → 状态管理 → @Observed |
| @ObjectLink | 对象引用 | ArkUI 指南 → 状态管理 → @ObjectLink |
| @Provide/@Consume | 跨层级 | ArkUI 指南 → 状态管理 → @Provide |
| @Builder | UI 构建函数 | ArkUI 指南 → 自定义组件 → @Builder |

### 3.3 系统能力

| 模块 | 用途 | 查询路径 |
|------|------|----------|
| @ohos.router | 页面路由 | API Reference → ArkUI → router |
| @ohos.data.preferences | 键值存储 | API Reference → 数据管理 → preferences |
| @ohos.data.relationalStore | 关系数据库 | API Reference → 数据管理 → relationalStore |
| @ohos.file.photoAccessHelper | 相册访问 | API Reference → 文件管理 → photoAccessHelper |
| @ohos.net.http | HTTP 请求 | API Reference → 网络 → http |
| @ohos.events.emitter | 事件总线 | API Reference → 事件通知 → emitter |
| @ohos.multimedia.image | 图片处理 | API Reference → 媒体 → image |
| @kit.AbilityKit | Ability 框架 | API Reference → Ability框架 |
| @kit.ArkUI | ArkUI 框架 | API Reference → ArkUI |
| @kit.PerformanceAnalysisKit | 性能分析 | API Reference → 性能分析 |

### 3.4 图片处理

| 能力 | 相关 API | 用途 |
|------|----------|------|
| 获取 PixelMap | image.createImageSource() | 从文件/URI 创建 PixelMap |
| 读取像素 | pixelMap.readPixelsToBuffer() | 读取像素数据到 ArrayBuffer |
| 写入像素 | pixelMap.writePixelsToBuffer() | 写入像素数据 |
| 缩放 | pixelMap.scale() | 缩放到指定尺寸 |
| Canvas 绘制 | CanvasRenderingContext2D | 绘制网格、色块 |

### 3.5 文件存储

| 能力 | 相关 API | 用途 |
|------|----------|------|
| 应用沙箱路径 | context.filesDir | 获取 app 私有目录 |
| 写入文件 | fileIo.write() | 保存图片/数据文件 |
| 读取文件 | fileIo.readText() | 读取 JSON 数据 |
| 临时目录 | context.tempDir | 临时文件 |
| 相册保存 | photoAccessHelper.createAsset() | 保存到系统相册 |

---

## 四、API 使用流程（强制）

```
1. 确定功能需要使用什么 API
        ↓
2. 在本文档"常用模块"中定位 API 模块名
        ↓
3. 访问 API Reference 官方文档，查找模块
        ↓
4. 确认：SDK 版本 → 参数列表 → 返回值 → 权限要求
        ↓
5. 查阅"官方 Samples"确认用法示例
        ↓
6. 编码实现
        ↓
7. 编译验证
```

**如果第 3 步无法找到 API**：停止实现，报告：
- 要实现的 API 名称
- 查阅的文档路径
- 无法找到的具体原因

---

## 五、已确认支持的 API（SDK 6.1.1 / API 24）

> 以下是经过本项目的编译验证的 API，可以安全使用。

| API | 验证状态 | 备注 |
|-----|----------|------|
| @Entry | ✅ 可用 | 页面入口装饰器 |
| @Component | ✅ 可用 | 组件装饰器 |
| @State | ✅ 可用 | 组件状态 |
| Tabs / TabContent | ✅ 可用 | 标签导航 |
| Column / Row / Flex | ✅ 可用 | 弹性布局 |
| Text | ✅ 可用 | 文本显示 |
| Button | ✅ 可用 | 按钮 |
| $r('app.color.xxx') | ✅ 可用 | 颜色资源引用 |
| $r('app.string.xxx') | ✅ 可用 | 字符串资源引用 |
| router.replaceUrl() | ✅ 可用 | 页面替换跳转 |
| Blank | ✅ 可用 | 空白占位 |
| .animation() | ✅ 可用 | 属性动画 |
| .scale() | ✅ 可用 | 缩放 |
| .opacity() | ✅ 可用 | 透明度 |
| .borderRadius() | ✅ 可用 | 圆角 |
| .shadow() | ✅ 可用 | 阴影 |
| @Builder | ✅ 可用 | 构建函数 |
| photoAccessHelper.PhotoViewPicker | ✅ 可用 | `@kit.MediaLibraryKit`：相册选择器 |
| image.createImageSource | ✅ 可用 | `@kit.ImageKit`：从 URI 创建 ImageSource |
| ImageSource.createPixelMap | ✅ 可用 | 解码为 PixelMap，支持 desiredSize 参数 |
| fileIo.openSync | ✅ 可用 | `@kit.CoreFileKit`：打开 URI 返回 File 对象 |
| image.createImageSource(fd) | ✅ 可用 | 接受 number(fd) 参数创建 ImageSource |

## 六、已确认不支持的 API（SDK 6.1.1 / API 24）

> 以下 API 已尝试使用但编译失败，应避免使用。

| API | 问题 | 替代方案 |
|-----|------|----------|
| SymbolGlyph($r('sys.symbol.rectangle_grid_2x2')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph($r('sys.symbol.rectangle_grid_2x2_fill')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph($r('sys.symbol.person_crop_circle')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph($r('sys.symbol.person_crop_circle_fill')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph($r('sys.symbol.tray')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph($r('sys.symbol.person_2')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph($r('sys.symbol.chevron_right')) | 图标不存在 | Text + emoji / SVG |
| SymbolGlyph.renderMode() | 方法不存在 | 删除调用 |
| 对象字面量类型 `{a: string}` | 严格模式禁止 | 使用显式 interface |

---

## 六点五、待验证 API（编码前必须确认）

> 以下 API 在 Phase 4 编辑器开发前需要查阅官方文档确认可用性。
> 不允许猜测——每个 API 必须在官方 API Reference 中找到对应条目。

| API | 用途 | 影响 Phase | 优先级 |
|-----|------|------------|--------|
| CanvasRenderingContext2D 全量方法 | 编辑器 Canvas 渲染 | Phase 4 | 🔴 高 |
| PanGesture + PinchGesture 并行 | 编辑器手势 | Phase 4 | 🔴 高 |
| bindSheet() | 材料统计/导出底部面板 | Phase 4 | 🟡 中 |
| CustomDialogController | 确认对话框 | Phase 4 | 🟡 中 |
| SymbolGlyph 官方支持列表 | 所有页面图标 | Phase 1 | 🟡 中 |
| WaterFlow 组件 | 广场瀑布流布局 | Phase 7 | 🟢 低 |
| LazyForEach | 大列表性能优化 | Phase 6 | 🟢 低 |
| photoAccessHelper.PhotoViewPicker | 图片选择器 | Phase 2 | ✅ 已验证 |

**降级方案**：
- `bindSheet()` 不可用 → 手动 Stack + translate 动画实现 Bottom Sheet
- `WaterFlow` 不可用 → 使用 Grid + 不等高 Item 手动实现
- 手势冲突 → 使用 GestureGroup 设置优先级

---

## 七、文档更新记录

| 日期 | 更新内容 |
|------|----------|
| 2026-07-09 | 初始创建，整理核心开发文档和常用模块 |
| 2026-07-09 | 新增"待验证 API"章节，标注 TODO(API_VERIFY) 项 |
