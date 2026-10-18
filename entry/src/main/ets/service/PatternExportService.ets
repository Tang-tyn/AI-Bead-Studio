/**
 * PatternExportService.ets - 独立绘制并保存拼豆图纸 PNG
 */
import { common } from '@kit.AbilityKit'
import { fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { drawing } from '@kit.ArkGraphics2D'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BeadPattern } from '../model/BeadPattern'
import { PatternColorCount, PatternStatistics } from '../model/PatternStatistics'
import { GridCell } from '../model/GridCell'
import { GRID_MAX_SIZE, GRID_MIN_SIZE } from '../utils/Constants'

const CELL_PIXEL_SIZE: number = 10
const PAGE_MARGIN: number = 28
const GRID_LEFT_MARGIN: number = 52
const HEADER_HEIGHT: number = 108
const LEGEND_TOP_GAP: number = 44
const LEGEND_ROW_HEIGHT: number = 32
const LEGEND_COLUMN_WIDTH: number = 260
const MAX_LEGEND_COLUMNS: number = 4

export class PatternExportService {
  private static instance: PatternExportService | null = null
  private exportSequence: number = 0

  static getInstance(): PatternExportService {
    if (PatternExportService.instance === null) {
      PatternExportService.instance = new PatternExportService()
    }
    return PatternExportService.instance
  }

  private constructor() {
  }

  /**
   * 通过系统图库保存确认，将当前图纸保存到系统图库。
   * @param pattern 当前图纸
   * @param statistics 当前图纸统计结果
   * @param context UIAbility 上下文
   * @returns 保存成功返回 true；用户取消返回 false
   */
  async exportToGallery(
    pattern: BeadPattern,
    statistics: PatternStatistics,
    context: common.UIAbilityContext
  ): Promise<boolean> {
    this.validateStatistics(pattern, statistics)
    const encodedPng: ArrayBuffer = await this.renderAndEncode(pattern, statistics)
    const fileBaseName: string = this.createUniqueFileBaseName(pattern)
    const temporaryPath: string = `${context.cacheDir}/${fileBaseName}.png`
    let temporaryFileCreated: boolean = false
    try {
      const temporaryFile: fileIo.File = fileIo.openSync(
        temporaryPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY
      )
      temporaryFileCreated = true
      try {
        const writtenBytes: number = fileIo.writeSync(temporaryFile.fd, encodedPng)
        if (writtenBytes !== encodedPng.byteLength) {
          throw new Error(`PNG 临时文件写入不完整：${writtenBytes}/${encodedPng.byteLength} 字节`)
        }
      } finally {
        fileIo.closeSync(temporaryFile)
      }

      const photoHelper: photoAccessHelper.PhotoAccessHelper =
        photoAccessHelper.getPhotoAccessHelper(context)
      const savedUris: Array<string> = await photoHelper.showAssetsCreationDialog(
        [fileUri.getUriFromPath(temporaryPath)],
        [{
          title: fileBaseName,
          fileNameExtension: 'png',
          photoType: photoAccessHelper.PhotoType.IMAGE
        }]
      )
      if (savedUris.length === 0 || savedUris[0] === '') {
        return false
      }
      this.writePngToUri(savedUris[0], encodedPng)
      return true
    } finally {
      if (temporaryFileCreated) {
        try {
          fileIo.unlinkSync(temporaryPath)
        } catch (err) {
          const message: string = err instanceof Error ? err.message : '未知错误'
          console.error('清理 PNG 临时文件失败：' + message)
        }
      }
    }
  }

  /**
   * 通过系统文档保存选择器将当前图纸保存到用户指定位置。
   * @param pattern 当前图纸
   * @param statistics 当前图纸统计结果
   * @param context UIAbility 上下文
   * @returns 已保存返回 true；用户取消返回 false
   */
  async exportToLocation(
    pattern: BeadPattern,
    statistics: PatternStatistics,
    context: common.UIAbilityContext
  ): Promise<boolean> {
    this.validateStatistics(pattern, statistics)
    const encodedPng: ArrayBuffer = await this.renderAndEncode(pattern, statistics)
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context)
    const savedUris: Array<string> = await documentPicker.save({
      newFileNames: [this.createUniqueFileBaseName(pattern)],
      fileSuffixChoices: ['PNG|.png']
    })
    if (savedUris.length === 0) {
      return false
    }

    this.writePngToUri(savedUris[0], encodedPng)
    return true
  }

  private writePngToUri(uri: string, encodedPng: ArrayBuffer): void {
    const outputFile: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.WRITE_ONLY)
    try {
      const writtenBytes: number = fileIo.writeSync(outputFile.fd, encodedPng)
      if (writtenBytes !== encodedPng.byteLength) {
        throw new Error(`PNG 图片写入不完整：${writtenBytes}/${encodedPng.byteLength} 字节`)
      }
    } finally {
      fileIo.closeSync(outputFile)
    }
  }

  private createUniqueFileBaseName(pattern: BeadPattern): string {
    this.exportSequence++
    return `BeadPattern_${pattern.gridWidth}x${pattern.gridHeight}_${Date.now()}_${this.exportSequence}`
  }

  private validateStatistics(pattern: BeadPattern, statistics: PatternStatistics): void {
    if (!Number.isInteger(pattern.gridWidth) || !Number.isInteger(pattern.gridHeight) ||
      pattern.gridWidth < GRID_MIN_SIZE || pattern.gridWidth > GRID_MAX_SIZE ||
      pattern.gridHeight < GRID_MIN_SIZE || pattern.gridHeight > GRID_MAX_SIZE) {
      throw new Error('图纸网格尺寸无效，已取消 PNG 导出')
    }

    const expectedByCode: Map<string, number> = new Map<string, number>()
    let countedBeads: number = 0
    for (let i: number = 0; i < statistics.colors.length; i++) {
      const entry: PatternColorCount = statistics.colors[i]
      if (!/^[A-Z][0-9]+$/.test(entry.code) ||
        !/^#[0-9A-Fa-f]{6}$/.test(entry.hexColor) ||
        !Number.isInteger(entry.count) || entry.count <= 0 ||
        expectedByCode.has(entry.code)) {
        throw new Error(`图纸色号统计数据无效：${entry.code}`)
      }
      expectedByCode.set(entry.code, entry.count)
      countedBeads += entry.count
    }
    if (countedBeads !== statistics.totalBeads || statistics.totalBeads <= 0) {
      throw new Error('图纸色号统计总数不一致，已取消 PNG 导出')
    }

    const actualByCode: Map<string, number> = new Map<string, number>()
    expectedByCode.forEach((_count: number, code: string) => {
      actualByCode.set(code, 0)
    })
    let actualInvalidCellCount: number = 0
    for (let row: number = 0; row < pattern.gridHeight; row++) {
      const rowCells: GridCell[] | undefined = pattern.cells[row]
      for (let col: number = 0; col < pattern.gridWidth; col++) {
        const cell: GridCell | undefined =
          rowCells === undefined ? undefined : rowCells[col]
        if (cell === undefined) {
          actualInvalidCellCount++
          continue
        }
        if (cell.colorId === '') {
          continue
        }
        const currentCount: number | undefined = actualByCode.get(cell.colorId)
        if (currentCount === undefined) {
          actualInvalidCellCount++
        } else {
          actualByCode.set(cell.colorId, currentCount + 1)
        }
      }
    }

    if (actualInvalidCellCount !== statistics.invalidCellCount) {
      throw new Error('图纸与材料统计已不一致，请重新生成后再导出')
    }
    let verifiedBeads: number = 0
    expectedByCode.forEach((expectedCount: number, code: string) => {
      const actualCount: number | undefined = actualByCode.get(code)
      if (actualCount !== expectedCount) {
        throw new Error(`图纸与色号 ${code} 的统计数量不一致，请重新生成后再导出`)
      }
      verifiedBeads += actualCount
    })
    if (verifiedBeads !== statistics.totalBeads) {
      throw new Error('图纸与材料总数不一致，请重新生成后再导出')
    }
  }

  private async renderAndEncode(
    pattern: BeadPattern,
    statistics: PatternStatistics
  ): Promise<ArrayBuffer> {
    const exportLayout: ExportLayout = this.createLayout(pattern, statistics)
    const outputPixelMap: image.PixelMap = image.createPixelMapSync({
      size: { width: exportLayout.canvasWidth, height: exportLayout.canvasHeight },
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      alphaType: image.AlphaType.UNPREMUL,
      editable: true
    })
    let packer: image.ImagePacker | null = null
    try {
      const drawingCanvas: drawing.Canvas = new drawing.Canvas(outputPixelMap)
      const brush: drawing.Brush = new drawing.Brush()
      drawingCanvas.attachBrush(brush)
      this.drawBackground(drawingCanvas, brush, exportLayout)
      this.drawHeading(drawingCanvas, brush, pattern, statistics)
      this.drawPattern(drawingCanvas, brush, exportLayout, pattern, statistics.colors)
      this.drawLegend(drawingCanvas, brush, exportLayout, statistics)
      packer = image.createImagePacker()
      if (packer === null) {
        throw new Error('无法创建 PNG 编码器')
      }
      return await packer.packToData(outputPixelMap, {
        format: 'image/png',
        quality: 100
      })
    } finally {
      if (packer !== null) {
        await packer.release()
      }
      await outputPixelMap.release()
    }
  }

  private createLayout(pattern: BeadPattern, statistics: PatternStatistics): ExportLayout {
    const legendColumns: number = Math.min(
      MAX_LEGEND_COLUMNS,
      Math.max(1, Math.ceil(statistics.colors.length / 14))
    )
    const gridPixelWidth: number = pattern.gridWidth * CELL_PIXEL_SIZE
    const gridPixelHeight: number = pattern.gridHeight * CELL_PIXEL_SIZE
    const legendWidth: number = PAGE_MARGIN * 2 + legendColumns * LEGEND_COLUMN_WIDTH
    const gridWidth: number = GRID_LEFT_MARGIN + gridPixelWidth + PAGE_MARGIN
    const canvasWidth: number = Math.max(legendWidth, gridWidth)
    const legendRows: number = Math.ceil(statistics.colors.length / legendColumns)
    const gridLeft: number = Math.floor((canvasWidth - gridPixelWidth) / 2)
    const gridTop: number = HEADER_HEIGHT
    const legendTop: number = gridTop + gridPixelHeight + LEGEND_TOP_GAP
    const canvasHeight: number = legendTop + 54 + legendRows * LEGEND_ROW_HEIGHT + PAGE_MARGIN
    return new ExportLayout(
      canvasWidth,
      canvasHeight,
      gridLeft,
      gridTop,
      gridPixelWidth,
      gridPixelHeight,
      legendTop,
      legendRows
    )
  }

  private drawBackground(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    exportLayout: ExportLayout
  ): void {
    this.setBrushColor(canvas, brush, '#FFFFFF')
    canvas.drawRect(0, 0, exportLayout.canvasWidth, exportLayout.canvasHeight)
  }

  private drawHeading(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    pattern: BeadPattern,
    statistics: PatternStatistics
  ): void {
    this.setBrushColor(canvas, brush, '#202124')
    const titleFont: drawing.Font = new drawing.Font()
    titleFont.setSize(26)
    const detailFont: drawing.Font = new drawing.Font()
    detailFont.setSize(17)
    this.drawText(canvas, titleFont, 'BEAD PATTERN', PAGE_MARGIN, 38)
    this.drawText(
      canvas,
      detailFont,
      `SIZE ${pattern.gridWidth} x ${pattern.gridHeight}    TOTAL ${statistics.totalBeads}`,
      PAGE_MARGIN,
      72
    )
  }

  private drawPattern(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    exportLayout: ExportLayout,
    pattern: BeadPattern,
    colors: PatternColorCount[]
  ): void {
    const colorByCode: Map<string, string> = new Map<string, string>()
    for (let i: number = 0; i < colors.length; i++) {
      colorByCode.set(colors[i].code, colors[i].hexColor)
    }

    for (let row: number = 0; row < pattern.gridHeight; row++) {
      const rowCells: GridCell[] | undefined = pattern.cells[row]
      if (rowCells === undefined) {
        this.setBrushBlendMode(canvas, brush, drawing.BlendMode.CLEAR)
        canvas.drawRect(
          exportLayout.gridLeft,
          exportLayout.gridTop + row * CELL_PIXEL_SIZE,
          exportLayout.gridLeft + exportLayout.gridPixelWidth,
          exportLayout.gridTop + (row + 1) * CELL_PIXEL_SIZE
        )
        this.setBrushBlendMode(canvas, brush, drawing.BlendMode.SRC_OVER)
        continue
      }
      let col: number = 0
      while (col < pattern.gridWidth) {
        const cell: GridCell | undefined = rowCells[col]
        const fillColor: string | undefined = cell === undefined
          ? undefined : colorByCode.get(cell.colorId)
        if (fillColor === undefined) {
          let emptyRunEnd: number = col + 1
          while (emptyRunEnd < pattern.gridWidth) {
            const nextCell: GridCell | undefined = rowCells[emptyRunEnd]
            const nextColor: string | undefined = nextCell === undefined
              ? undefined : colorByCode.get(nextCell.colorId)
            if (nextColor !== undefined) {
              break
            }
            emptyRunEnd++
          }
          this.setBrushBlendMode(canvas, brush, drawing.BlendMode.CLEAR)
          canvas.drawRect(
            exportLayout.gridLeft + col * CELL_PIXEL_SIZE,
            exportLayout.gridTop + row * CELL_PIXEL_SIZE,
            exportLayout.gridLeft + emptyRunEnd * CELL_PIXEL_SIZE,
            exportLayout.gridTop + (row + 1) * CELL_PIXEL_SIZE
          )
          this.setBrushBlendMode(canvas, brush, drawing.BlendMode.SRC_OVER)
          col = emptyRunEnd
          continue
        }
        let runEnd: number = col + 1
        while (runEnd < pattern.gridWidth) {
          const nextCell: GridCell | undefined = rowCells[runEnd]
          if (nextCell === undefined || colorByCode.get(nextCell.colorId) !== fillColor) {
            break
          }
          runEnd++
        }
        this.setBrushColor(canvas, brush, fillColor)
        canvas.drawRect(
          exportLayout.gridLeft + col * CELL_PIXEL_SIZE,
          exportLayout.gridTop + row * CELL_PIXEL_SIZE,
          exportLayout.gridLeft + runEnd * CELL_PIXEL_SIZE,
          exportLayout.gridTop + (row + 1) * CELL_PIXEL_SIZE
        )
        col = runEnd
      }
    }
    this.drawGridLines(canvas, brush, exportLayout, pattern)
    this.drawCoordinates(canvas, brush, exportLayout, pattern)
  }

  private drawGridLines(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    exportLayout: ExportLayout,
    pattern: BeadPattern
  ): void {
    this.setBrushColor(canvas, brush, '#777777')
    for (let col: number = 1; col < pattern.gridWidth; col++) {
      const lineWidth: number = col % 5 === 0 ? 2 : 1
      const lineX: number = exportLayout.gridLeft + col * CELL_PIXEL_SIZE
      canvas.drawRect(
        lineX - Math.floor(lineWidth / 2),
        exportLayout.gridTop,
        lineX - Math.floor(lineWidth / 2) + lineWidth,
        exportLayout.gridTop + exportLayout.gridPixelHeight
      )
    }
    for (let row: number = 1; row < pattern.gridHeight; row++) {
      const lineWidth: number = row % 5 === 0 ? 2 : 1
      const lineY: number = exportLayout.gridTop + row * CELL_PIXEL_SIZE
      canvas.drawRect(
        exportLayout.gridLeft,
        lineY - Math.floor(lineWidth / 2),
        exportLayout.gridLeft + exportLayout.gridPixelWidth,
        lineY - Math.floor(lineWidth / 2) + lineWidth
      )
    }
    canvas.drawRect(
      exportLayout.gridLeft,
      exportLayout.gridTop,
      exportLayout.gridLeft + exportLayout.gridPixelWidth,
      exportLayout.gridTop + 1
    )
    canvas.drawRect(
      exportLayout.gridLeft,
      exportLayout.gridTop + exportLayout.gridPixelHeight - 1,
      exportLayout.gridLeft + exportLayout.gridPixelWidth,
      exportLayout.gridTop + exportLayout.gridPixelHeight
    )
    canvas.drawRect(
      exportLayout.gridLeft,
      exportLayout.gridTop,
      exportLayout.gridLeft + 1,
      exportLayout.gridTop + exportLayout.gridPixelHeight
    )
    canvas.drawRect(
      exportLayout.gridLeft + exportLayout.gridPixelWidth - 1,
      exportLayout.gridTop,
      exportLayout.gridLeft + exportLayout.gridPixelWidth,
      exportLayout.gridTop + exportLayout.gridPixelHeight
    )
  }

  private drawCoordinates(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    exportLayout: ExportLayout,
    pattern: BeadPattern
  ): void {
    this.setBrushColor(canvas, brush, '#404040')
    const labelFont: drawing.Font = new drawing.Font()
    labelFont.setSize(11)
    for (let col: number = 5; col <= pattern.gridWidth; col += 5) {
      const labelX: number = exportLayout.gridLeft + (col - 1) * CELL_PIXEL_SIZE - 7
      this.drawText(canvas, labelFont, `${col}`, labelX, exportLayout.gridTop - 8)
    }
    for (let row: number = 5; row <= pattern.gridHeight; row += 5) {
      const labelY: number = exportLayout.gridTop + (row - 1) * CELL_PIXEL_SIZE + 5
      this.drawText(canvas, labelFont, `${row}`, exportLayout.gridLeft - 34, labelY)
    }
  }

  private drawLegend(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    exportLayout: ExportLayout,
    statistics: PatternStatistics
  ): void {
    this.setBrushColor(canvas, brush, '#202124')
    const headingFont: drawing.Font = new drawing.Font()
    headingFont.setSize(20)
    const itemFont: drawing.Font = new drawing.Font()
    itemFont.setSize(15)
    this.drawText(
      canvas,
      headingFont,
      'COLORS AND MATERIALS',
      PAGE_MARGIN,
      exportLayout.legendTop + 25
    )
    for (let i: number = 0; i < statistics.colors.length; i++) {
      const column: number = Math.floor(i / exportLayout.legendRows)
      const row: number = i % exportLayout.legendRows
      const itemX: number = PAGE_MARGIN + column * LEGEND_COLUMN_WIDTH
      const itemY: number = exportLayout.legendTop + 54 + row * LEGEND_ROW_HEIGHT
      const colorEntry: PatternColorCount = statistics.colors[i]
      this.setBrushColor(canvas, brush, colorEntry.hexColor)
      canvas.drawRect(itemX, itemY - 14, itemX + 20, itemY + 6)
      this.setBrushColor(canvas, brush, '#202124')
      this.drawText(canvas, itemFont, colorEntry.code, itemX + 28, itemY + 2)
      this.drawText(
        canvas,
        itemFont,
        `x ${colorEntry.count}`,
        itemX + LEGEND_COLUMN_WIDTH - 78,
        itemY + 2
      )
    }
  }

  private drawText(canvas: drawing.Canvas, font: drawing.Font, text: string, x: number, y: number): void {
    canvas.drawTextBlob(drawing.TextBlob.makeFromString(text, font), x, y)
  }

  private setBrushColor(canvas: drawing.Canvas, brush: drawing.Brush, hexColor: string): void {
    canvas.detachBrush()
    const red: number = parseInt(hexColor.slice(1, 3), 16)
    const green: number = parseInt(hexColor.slice(3, 5), 16)
    const blue: number = parseInt(hexColor.slice(5, 7), 16)
    brush.setColor(255, red, green, blue)
    canvas.attachBrush(brush)
  }

  private setBrushBlendMode(
    canvas: drawing.Canvas,
    brush: drawing.Brush,
    blendMode: drawing.BlendMode
  ): void {
    canvas.detachBrush()
    brush.setBlendMode(blendMode)
    canvas.attachBrush(brush)
  }
}

class ExportLayout {
  canvasWidth: number
  canvasHeight: number
  gridLeft: number
  gridTop: number
  gridPixelWidth: number
  gridPixelHeight: number
  legendTop: number
  legendRows: number

  constructor(
    canvasWidth: number,
    canvasHeight: number,
    gridLeft: number,
    gridTop: number,
    gridPixelWidth: number,
    gridPixelHeight: number,
    legendTop: number,
    legendRows: number
  ) {
    this.canvasWidth = canvasWidth
    this.canvasHeight = canvasHeight
    this.gridLeft = gridLeft
    this.gridTop = gridTop
    this.gridPixelWidth = gridPixelWidth
    this.gridPixelHeight = gridPixelHeight
    this.legendTop = legendTop
    this.legendRows = legendRows
  }
}
