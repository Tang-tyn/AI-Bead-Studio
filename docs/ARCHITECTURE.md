# ARCHITECTURE.md — 整体架构设计

## 1. 分层架构

```
┌──────────────────────────────────────────────────────┐
│                    VIEW 层                            │
│  pages/ + view/components/ + view/common/           │
│  - 渲染 UI，绑定 ViewModel 状态                      │
│  - 转发用户事件给 ViewModel                          │
│  - 使用 @Component / @Entry / @Builder              │
│  - 不包含业务逻辑                                    │
├──────────────────────────────────────────────────────┤
│                  VIEWMODEL 层                         │
│  viewmodel/                                          │
│  - 持有 UI 状态（class 属性）                        │
│  - 编排业务逻辑流程                                  │
│  - 调用 Service 层                                   │
│  - 使用 @Observed 装饰类 + View 中 @ObjectLink 引用  │
│  - 不导入 ArkUI 类型                                 │
├──────────────────────────────────────────────────────┤
│                  SERVICE 层                           │
│  service/                                            │
│  - 具体计算/IO 操作（单例）                          │
│  - 图片处理、颜色匹配、数据库、网络、导出            │
│  - 不导入 ViewModel 或 ArkUI 类型                    │
├──────────────────────────────────────────────────────┤
│               MODEL + UTILS 层                        │
│  model/ + utils/ + data/                            │
│  - 纯数据结构 + 纯工具函数                           │
│  - 不依赖上层                                        │
└──────────────────────────────────────────────────────┘
```

## 2. 依赖方向（单向）

```
View → ViewModel → Service → Model/Utils
        ↓              ↓
    @Observed     getInstance()
  @ObjectLink     单例模式
```

- View 永远不直接访问 Service 或 Model
- ViewModel 永远不导入 ArkUI 类型
- Service 永远不导入 ViewModel 或 View 层

## 3. 状态管理策略

| 场景 | 方案 | 说明 |
|------|------|------|
| 组件内部状态 | @State | 影响当前组件 UI 的状态 |
| 父子传值（单向） | @Prop | 父改子不感知 |
| 父子传值（双向） | @Link | 父子同步 |
| Model 深层监听 | @Observed + @ObjectLink | Model 属性变化自动刷新 |
| ViewModel 状态 | @Observed + @ObjectLink | ViewModel 属性变化自动通知 View 刷新 |
| 跨层级共享 | @Provide + @Consume | 主题/用户信息等全局状态 |
| 跨 Tab 通信 | @ohos.events.emitter | 松耦合事件总线 |

## 4. 导航与路由（已确认）

### 4.1 最终 Tab 架构

```
MainPage (4个底部Tab)
├── Tab 0: HomePage     首页     — 项目管理 + 灵感发现（不承担主要创作入口）
├── Tab 1: CreatorPage  创作中心  — 所有新创作流程入口
├── Tab 2: SquarePage   作品广场  — 社区浏览
└── Tab 3: ProfilePage  个人中心  — 我的作品/收藏/设置
```

**页面职责边界（已确认）**：

| 页面 | 职责 | 不负责 |
|------|------|--------|
| HomePage | 项目浏览、灵感发现 | 不承担主要创作入口（快捷操作可跳转CreatorPage） |
| CreatorPage | AI创作 + 图片转图纸双入口 | 不展示项目列表 |
| PatternEditorPage | 全屏编辑工作区 | **不属于任何Tab，独立@Entry页面** |

### 4.2 路由注册

```
路由注册 (main_pages.json)
├── pages/Index                    ← 闪屏（应用入口）
├── pages/MainPage                 ← 主页（4Tab容器）
├── pages/creator/AICreatePage     ← AI创作
├── pages/creator/ImageImportPage  ← 图片导入
├── pages/creator/PatternEditorPage ← 图纸编辑器
├── pages/community/WorkDetailPage ← 作品详情
├── pages/community/UserProfilePage ← 用户主页
├── pages/mine/MyWorksPage         ← 我的作品
├── pages/mine/MyFavoritesPage     ← 我的收藏
└── pages/settings/SettingsPage    ← 设置

Tab内嵌组件（不注册路由，直接 import）
├── pages/home/HomePage            ← Tab 0
├── pages/creator/CreatorPage      ← Tab 1
├── pages/community/SquarePage     ← Tab 2
└── pages/mine/MinePage           ← Tab 3
```

## 5. 数据存储策略

| 数据 | 存储方式 | 说明 |
|------|----------|------|
| 项目数据 | relationalStore (RDB) | 结构化数据，可查询 |
| 用户设置 | Preferences (KV) | 键值对，轻量 |
| 调色板预设 | rawfile JSON | 只读，打包在 APK |
| 项目缩略图 | app sandbox 文件系统 | PNG 图片 |
| 自定义调色板 | Preferences (JSON string) | 小数据量 |

## 6. 社区数据流（Phase 7）

```
SquarePage → CommunityService.fetchWorks()
          → 瀑布流分页加载
          → 本地缓存降级（离线可用）

WorkDetailPage → CommunityService.fetchDetail(id)
              → 展示大图 + 评论列表 + 点赞收藏状态

UserProfilePage → CommunityService.fetchUser(id)
               → 用户作品集 + 收藏集

发布 → CommunityService.publish({pattern, image, title, tags, category})
     → 上传图纸数据 + 成品图 + 标签分类
```
