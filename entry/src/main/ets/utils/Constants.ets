/**
 * Constants.ets - 全局常量定义
 *
 * 【写给零基础学习者】
 * 这个文件就像一个"字典"，集中管理项目中所有固定不变的值。
 * 好处是：如果要改一个值，只需要改这里一处，所有引用它的地方自动生效。
 * 比如你觉得"撤销50步"太多，只需改 UNDO_MAX_STEPS = 30，不用满世界搜索。
 */

// ==================== 应用基础信息 ====================

/** 应用名称 */
export const APP_NAME = 'AI拼豆'

/** 应用版本号（遵循语义化版本规范：主版本.次版本.修订号） */
export const APP_VERSION = '1.0.0'

// ==================== 拼豆钉板尺寸 ====================

/** 小钉板尺寸（29×29，适合入门和快速创作） */
export const PEGBOARD_SMALL = 29

/** 大钉板尺寸（58×58，标准拼豆底板） */
export const PEGBOARD_LARGE = 58

/** 默认新建项目的钉板尺寸 */
export const PEGBOARD_DEFAULT = PEGBOARD_SMALL

/** 用户可设置的最小网格尺寸 */
export const GRID_MIN_SIZE = 10

/** 用户可设置的最大网格尺寸 */
export const GRID_MAX_SIZE = 200

// ==================== 拼豆品牌标识 ====================

export const BRAND_HAMA = 'hama'
export const BRAND_PERLER = 'perler'
export const BRAND_ARTKAL = 'artkal'
export const BRAND_CUSTOM = 'custom'

/** 首次启动使用的默认品牌 */
export const BRAND_DEFAULT = BRAND_HAMA

// ==================== 珠子物理尺寸（毫米） ====================

export const BEAD_SIZE_MIDI = 5.0    // 标准Midi珠子
export const BEAD_SIZE_MINI = 2.5    // Mini珠子
export const BEAD_SIZE_MAXI = 10.0   // Maxi珠子

// ==================== 编辑器 ====================

/** 撤销/重做最大存储步数 */
export const UNDO_MAX_STEPS = 50

/** 画布缩放范围 */
export const ZOOM_MIN = 0.25          // 最小25%
export const ZOOM_MAX = 4.0           // 最大400%
export const ZOOM_DEFAULT = 1.0       // 默认100%
export const ZOOM_STEP = 0.25         // 每次缩放25%

// ==================== 图片处理 ====================

/** 导入图片最大宽度（超过会自动缩放，避免内存不足） */
export const IMAGE_MAX_WIDTH = 2000

/** 导入图片最大高度 */
export const IMAGE_MAX_HEIGHT = 2000

/** 图片转图纸最大处理时间（毫秒），超时则提示用户 */
export const CONVERT_TIMEOUT = 30000

// ==================== AI 创作 ====================

/** AI请求超时时间（毫秒），AI接口通常较慢 */
export const AI_REQUEST_TIMEOUT = 60000

/** AI生成的默认风格 */
export const AI_DEFAULT_STYLE = 'q_style'

// ==================== 本地存储 ====================

export const PREF_FILE_NAME = 'bead_studio_preferences'
export const DB_NAME = 'bead_studio.db'
export const DB_VERSION = 1
export const TABLE_PROJECTS = 'projects'

// ==================== Preferences 键名 ====================

export const PREF_DEFAULT_BRAND = 'default_brand'
export const PREF_DEFAULT_PEGBOARD = 'default_pegboard'
export const PREF_DEFAULT_PALETTE = 'default_palette'
export const PREF_THEME_MODE = 'theme_mode'
export const PREF_LANGUAGE = 'language'

// ==================== 页面路由路径 ====================
// 【知识点】路由就是"页面地址"，就像网址一样。HarmonyOS通过路由找到对应页面。

/** 主页（Tab容器） */
export const ROUTE_MAIN = 'pages/MainPage'

/** 首页Tab - 项目列表 */
export const ROUTE_HOME = 'pages/home/HomePage'

/** 创作Tab - 创作入口 */
export const ROUTE_CREATOR = 'pages/creator/CreatorPage'

/** 创作 - AI创作页 */
export const ROUTE_AI_CREATE = 'pages/creator/AICreatePage'

/** 创作 - 图片导入页 */
export const ROUTE_IMAGE_IMPORT = 'pages/creator/ImageImportPage'

/** 创作 - 图纸编辑器 */
export const ROUTE_EDITOR = 'pages/creator/PatternEditorPage'

/** 广场Tab - 作品广场 */
export const ROUTE_SQUARE = 'pages/community/SquarePage'

/** 广场 - 作品详情 */
export const ROUTE_WORK_DETAIL = 'pages/community/WorkDetailPage'

/** 广场 - 用户主页 */
export const ROUTE_USER_PROFILE = 'pages/community/UserProfilePage'

/** 我的Tab - 个人中心 */
export const ROUTE_MINE = 'pages/mine/MinePage'

/** 我的 - 我的作品列表 */
export const ROUTE_MY_WORKS = 'pages/mine/MyWorksPage'

/** 我的 - 我的收藏列表 */
export const ROUTE_MY_FAVORITES = 'pages/mine/MyFavoritesPage'

/** 我的 - 设置页 */
export const ROUTE_SETTINGS = 'pages/settings/SettingsPage'

/** 测试页 — 调色板验证 */
export const ROUTE_PALETTE_TEST = 'pages/test/PaletteTestPage'

// ==================== 枚举类型 ====================
// 【知识点】枚举(enum)是一种特殊的数据类型，限定变量只能取预定义的几个值。
// 比如：主题只能是"跟随系统/浅色/深色"之一，不能是其他值。

/** 主题模式 */
export enum ThemeMode {
  SYSTEM = 'system',   // 跟随系统
  LIGHT = 'light',     // 浅色模式（白底黑字）
  DARK = 'dark'        // 深色模式（黑底白字）
}

/** 项目状态 */
export enum ProjectStatus {
  DRAFT = 'draft',           // 草稿（编辑中）
  COMPLETED = 'completed',   // 已完成
  EXPORTED = 'exported'      // 已导出
}

/** 编辑器工具 */
export enum ToolType {
  PEN = 'pen',           // 画笔：点击单个格子填色
  FILL = 'fill',         // 填充：点击一个区域全部填充同色
  ERASER = 'eraser',     // 橡皮：点击格子恢复为空
  PICKER = 'picker'      // 吸色器：长按一个格子获取其颜色
}

/** 导出格式 */
export enum ExportFormat {
  PNG = 'png',           // 图片格式（通用性最好）
  SVG = 'svg',           // 矢量格式（可无损放大，预留）
  JSON = 'json',         // 数据格式（可导入其他工具）
  CSV = 'csv'            // 表格格式（方便打印材料清单）
}

/** AI 风格类型 */
export enum AIStyleType {
  Q_STYLE = 'q_style',           // Q版风格（大头卡通）
  COMIC = 'comic',               // 漫画风（线条明快）
  PIXEL = 'pixel',               // 像素风（复古游戏）
  WATERCOLOR = 'watercolor',     // 水彩风（柔和艺术）
  SKETCH = 'sketch'              // 素描风（线稿）
}

/** 社区作品分类标签 */
export enum WorkCategory {
  ALL = 'all',             // 全部
  ANIMAL = 'animal',       // 动物
  CARTOON = 'cartoon',     // 卡通
  LANDSCAPE = 'landscape', // 风景
  PATTERN = 'pattern',     // 花纹
  PORTRAIT = 'portrait',   // 人物
  FOOD = 'food',           // 美食
  HOLIDAY = 'holiday',     // 节日
  OTHER = 'other'          // 其他
}

// ==================== 事件常量（跨组件通信） ====================
// 【知识点】emitter 就像"对讲机"，一个组件发消息，另一个组件收听。
// 用来实现Tab之间、页面之间的解耦通信。

/** 打开编辑器并加载指定项目 */
export const EVENT_OPEN_PROJECT_IN_EDITOR = 'event_open_project_in_editor'

/** 项目列表发生变化（新建/删除/修改后通知刷新） */
export const EVENT_PROJECT_LIST_CHANGED = 'event_project_list_changed'

/** 切换到指定Tab */
export const EVENT_SWITCH_TAB = 'event_switch_tab'

/** 社区作品被点赞 */
export const EVENT_WORK_LIKED = 'event_work_liked'

/** 社区作品被收藏 */
export const EVENT_WORK_FAVORITED = 'event_work_favorited'
