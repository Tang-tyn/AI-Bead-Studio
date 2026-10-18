/**
 * PatternSession.ets - 暂存图片转换生成的内存项目
 */
import { Project } from '../model/Project'

export class PatternSession {
  private static project: Project | null = null

  /**
   * 保存当前生成的内存项目。
   * @param project 待暂存项目
   * @returns 无返回值
   */
  static save(project: Project): void {
    PatternSession.project = project
  }

  /**
   * 取出并清空暂存项目。
   * @returns 暂存项目；没有项目时返回 null
   */
  static consume(): Project | null {
    const project: Project | null = PatternSession.project
    PatternSession.project = null
    return project
  }

  /**
   * 清空暂存项目。
   * @returns 无返回值
   */
  static clear(): void {
    PatternSession.project = null
  }
}
