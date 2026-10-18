/**
 * BeadGrid.ets - 使用 Canvas 展示静态拼豆图纸网格
 */
import { BeadPattern } from '../../model/BeadPattern'
import { GridCell } from '../../model/GridCell'

/** 通过 Canvas 按 BeadPattern 的行列顺序绘制静态 MARD 拼豆网格。 */
@Component
export struct BeadGrid {
  @Prop @Watch('onGridDataChanged') pattern: BeadPattern =
    new BeadPattern('', '', 1, 1, 'mard-221', [], 0, 0)
  @Prop @Watch('onGridDataChanged') colorByCode: Map<string, string> = new Map<string, string>()
  @State private unresolvedCellCount: number = 0

  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D()
  private canvasReady: boolean = false

  aboutToAppear(): void {
    this.updateUnresolvedCellCount()
  }

  build() {
    Column() {
      if (this.unresolvedCellCount > 0) {
        Text(`${this.unresolvedCellCount} 个格子没有有效的 MARD 色号，已留空显示`)
          .fontSize(12)
          .fontColor($r('app.color.color_error'))
          .width('100%')
          .margin({ bottom: 8 })
      }

      Canvas(this.context)
        .width('100%')
        .aspectRatio(this.getGridAspectRatio())
        .onReady(() => {
          this.canvasReady = true
          this.updateUnresolvedCellCount()
          this.drawGrid()
        })
        .onAreaChange(() => {
          this.drawGrid()
        })
    }
    .width('100%')
    .backgroundColor($r('app.color.color_bg_surface'))
  }

  private onGridDataChanged(): void {
    this.updateUnresolvedCellCount()
    this.drawGrid()
  }

  private getGridAspectRatio(): number {
    if (this.pattern.gridWidth <= 0 || this.pattern.gridHeight <= 0) {
      return 1
    }
    return this.pattern.gridWidth / this.pattern.gridHeight
  }

  private updateUnresolvedCellCount(): void {
    let unresolvedCount: number = 0
    for (let row: number = 0; row < this.pattern.gridHeight; row++) {
      for (let col: number = 0; col < this.pattern.gridWidth; col++) {
        const colorCode: string | null = this.getCellColorCode(row, col)
        if (colorCode === null) {
          unresolvedCount++
        }
      }
    }
    this.unresolvedCellCount = unresolvedCount
  }

  private getCellColorCode(row: number, col: number): string | null {
    if (row >= this.pattern.cells.length) {
      return null
    }
    const rowCells: GridCell[] = this.pattern.cells[row]
    if (rowCells === undefined || col >= rowCells.length) {
      return null
    }
    const cell: GridCell = rowCells[col]
    if (cell === undefined || cell.colorId === '') {
      return ''
    }
    const fillColor: string | undefined = this.colorByCode.get(cell.colorId)
    if (fillColor === undefined || !this.isValidCanvasColor(fillColor)) {
      return null
    }
    return cell.colorId
  }

  private isValidCanvasColor(fillColor: string): boolean {
    return /^#[0-9A-Fa-f]{6}$/.test(fillColor)
  }

  private drawGrid(): void {
    if (!this.canvasReady || this.context.width <= 0 || this.context.height <= 0) {
      return
    }

    const gridWidth: number = this.pattern.gridWidth
    const gridHeight: number = this.pattern.gridHeight
    if (gridWidth <= 0 || gridHeight <= 0) {
      this.context.clearRect(0, 0, this.context.width, this.context.height)
      return
    }

    const cellSize: number = Math.min(
      this.context.width / gridWidth,
      this.context.height / gridHeight
    )
    const renderedWidth: number = cellSize * gridWidth
    const renderedHeight: number = cellSize * gridHeight
    const originX: number = (this.context.width - renderedWidth) / 2
    const originY: number = (this.context.height - renderedHeight) / 2
    this.context.clearRect(0, 0, this.context.width, this.context.height)

    for (let row: number = 0; row < gridHeight; row++) {
      let col: number = 0
      while (col < gridWidth) {
        const colorCode: string | null = this.getCellColorCode(row, col)
        if (colorCode === null || colorCode === '') {
          col++
          continue
        }

        const fillColor: string | undefined = this.colorByCode.get(colorCode)
        if (fillColor === undefined || !this.isValidCanvasColor(fillColor)) {
          col++
          continue
        }

        let runEnd: number = col + 1
        while (runEnd < gridWidth) {
          const nextCode: string | null = this.getCellColorCode(row, runEnd)
          if (nextCode === null || nextCode === '') {
            break
          }
          const nextColor: string | undefined = this.colorByCode.get(nextCode)
          if (nextColor === undefined || !this.isValidCanvasColor(nextColor) ||
            nextColor !== fillColor) {
            break
          }
          runEnd++
        }

        this.context.fillStyle = fillColor
        this.context.fillRect(
          originX + col * cellSize,
          originY + row * cellSize,
          (runEnd - col) * cellSize,
          cellSize
        )
        col = runEnd
      }
    }

    this.drawGridLines(gridWidth, gridHeight, cellSize, originX, originY)
  }

  private drawGridLines(
    gridWidth: number,
    gridHeight: number,
    cellSize: number,
    originX: number,
    originY: number
  ): void {
    const minorPath: Path2D = new Path2D()
    const majorPath: Path2D = new Path2D()
    this.context.beginPath()
    for (let col: number = 1; col < gridWidth; col++) {
      const x: number = originX + col * cellSize
      const path: Path2D = col % 5 === 0 ? majorPath : minorPath
      path.moveTo(x, originY)
      path.lineTo(x, originY + gridHeight * cellSize)
    }
    for (let row: number = 1; row < gridHeight; row++) {
      const y: number = originY + row * cellSize
      const path: Path2D = row % 5 === 0 ? majorPath : minorPath
      path.moveTo(originX, y)
      path.lineTo(originX + gridWidth * cellSize, y)
    }

    const minorLineWidth: number = Math.min(0.7, cellSize * 0.08)
    const majorLineWidth: number = Math.min(
      cellSize * 0.4,
      minorLineWidth * 2.5
    )
    this.context.strokeStyle = Color.Gray
    this.context.globalAlpha = 1
    this.context.lineWidth = minorLineWidth
    this.context.stroke(minorPath)
    this.context.lineWidth = majorLineWidth
    this.context.stroke(majorPath)
    this.context.globalAlpha = 1

    this.context.strokeStyle = Color.Gray
    this.context.lineWidth = Math.min(1, cellSize * 0.4)
    this.context.strokeRect(
      originX,
      originY,
      gridWidth * cellSize,
      gridHeight * cellSize
    )
  }
}
