/**
 * PatternStatistics.ets - 图纸实际用色与材料数量统计模型
 */
export class PatternColorCount {
  code: string
  hexColor: string
  count: number

  constructor(code: string, hexColor: string, count: number) {
    this.code = code
    this.hexColor = hexColor
    this.count = count
  }
}

export class PatternStatistics {
  colors: PatternColorCount[]
  totalBeads: number
  invalidCellCount: number

  constructor(colors: PatternColorCount[], totalBeads: number, invalidCellCount: number) {
    this.colors = colors
    this.totalBeads = totalBeads
    this.invalidCellCount = invalidCellCount
  }
}
