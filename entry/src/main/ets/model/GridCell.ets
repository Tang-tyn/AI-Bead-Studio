/**
 * GridCell.ets - 拼豆网格单元格模型
 *
 * 【职责】
 * 表示拼豆图纸中一个最小单元格。存储该格子放置的珠子颜色引用。
 *
 * 【设计决策：极简 Cell】
 * - 只存 colorId（字符串引用），不存完整 BeadColor 对象
 *   原因（DD-002）：200×200 网格 = 40,000 个 Cell
 *     存 string(~32B) vs 存 BeadColor 对象(~200B)
 *     差异：1.28MB vs 8MB — 节省 84% 内存
 * - 空字符串 "" 表示空格子（未放珠子）
 *   原因：'' 可以 JSON 序列化，null 在某些 ArkTS 场景下有兼容问题
 * - 不存 row/col 坐标
 *   原因：坐标由 cells[row][col] 二维数组索引唯一确定
 *   存坐标会造成数据冗余 + 不一致风险（移动格子时需同步更新坐标）
 *
 * 【使用场景】
 * BeadPattern.cells[row][col] = new GridCell('hama_01')
 * BeadPattern.cells[row][col].colorId === '' → 此格为空
 *
 * 【数据示例】
 * { colorId: 'hama_01' }   → 此格放了 Hama 白色珠子
 * { colorId: '' }          → 此格为空
 */
export class GridCell {
  /**
   * 该格子的颜色引用。
   * 值为 BeadColor.id，空字符串 '' 表示空格。
   */
  colorId: string

  /**
   * 创建一个网格单元格
   *
   * @param colorId 颜色 ID 引用，默认 ''（空格）
   */
  constructor(colorId: string = '') {
    this.colorId = colorId
  }
}
