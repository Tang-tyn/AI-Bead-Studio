/**
 * Project.ets - 项目模型
 *
 * 【职责】
 * 包装用户的一次完整创作。包含图纸数据（BeadPattern）+ 项目元数据。
 * 是本地存储和项目列表的基本单元。
 *
 * 【数据关系】
 * Project (1) ──owns──→ (1) BeadPattern
 *   project.pattern 直接持有图纸对象，不通过外键引用。
 *   原因：一个项目 = 一份图纸，1:1 关系无需解耦。
 *
 * 【sourceImageUri vs thumbnailUri】
 * sourceImageUri：原始导入图片的路径（如 PhotoViewPicker 返回的 URI）
 *   → 用途：追溯来源、"重新导入"功能
 * thumbnailUri：项目中保存的缩略图路径（app 沙箱内的 PNG 文件）
 *   → 用途：HomePage 项目列表快速预览，避免每次渲染完整画布
 *
 * 【status 生命周期】
 * DRAFT → (编辑完成) → COMPLETED → (导出) → EXPORTED
 *    ↑                                                      │
 *    └────────────── (继续编辑) ←──────────────────────────┘
 *
 * 【数据示例】
 * {
 *   id: 'proj_001',
 *   name: '小猫拼豆',
 *   pattern: BeadPattern { id:'pattern_001', gridWidth:29, ... },
 *   sourceImageUri: 'file://media/Photo/1/IMG_001.jpg',
 *   thumbnailUri: '/data/storage/.../thumb_proj_001.png',
 *   status: ProjectStatus.DRAFT,
 *   createdAt: 1720512000000,
 *   updatedAt: 1720512000000
 * }
 */
import { BeadPattern } from './BeadPattern'

/**
 * 项目状态枚举
 *
 * DRAFT:     草稿 — 用户正在编辑
 * COMPLETED: 已完成 — 用户标记为完成
 * EXPORTED:  已导出 — 已生成 PNG/JSON 等导出文件
 */
export enum ProjectStatus {
  DRAFT = 'draft',
  COMPLETED = 'completed',
  EXPORTED = 'exported'
}

export class Project {
  /** 项目唯一标识 */
  id: string

  /** 用户命名的项目名称，如 "小猫拼豆" */
  name: string

  /** 拼豆图纸数据。1:1 关系，一个项目包含一份图纸 */
  pattern: BeadPattern

  /**
   * 原始导入图片的路径。
   * Phase 2 图片导入时填充，空字符串 = 非图片导入来源（如 AI 生成）
   */
  sourceImageUri: string

  /**
   * 项目缩略图路径（app 沙箱内 PNG 文件）。
   * HomePage 项目列表展示时使用，避免加载完整图纸渲染
   */
  thumbnailUri: string

  /** 项目状态：草稿 / 已完成 / 已导出 */
  status: ProjectStatus

  /** 项目创建时间，Unix 毫秒时间戳 */
  createdAt: number

  /** 项目最后更新时间，Unix 毫秒时间戳 */
  updatedAt: number

  /**
   * 创建一个项目
   *
   * @param id 项目唯一标识
   * @param name 项目名称
   * @param pattern 拼豆图纸
   * @param sourceImageUri 原始图片路径，默认 ''
   * @param thumbnailUri 缩略图路径，默认 ''
   * @param status 项目状态，默认 DRAFT
   * @param createdAt 创建时间戳
   * @param updatedAt 更新时间戳
   */
  constructor(
    id: string,
    name: string,
    pattern: BeadPattern,
    sourceImageUri: string = '',
    thumbnailUri: string = '',
    status: ProjectStatus = ProjectStatus.DRAFT,
    createdAt: number,
    updatedAt: number
  ) {
    this.id = id
    this.name = name
    this.pattern = pattern
    this.sourceImageUri = sourceImageUri
    this.thumbnailUri = thumbnailUri
    this.status = status
    this.createdAt = createdAt
    this.updatedAt = updatedAt
  }
}
