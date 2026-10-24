/**
 * CropRect.ets - 图片剪裁区域
 *
 * 【职责】
 * 描述用户在剪裁页选定的区域，坐标为源图像素坐标。
 * 剪裁不修改原 PixelMap（PixelMap.crop 为就地修改，会破坏"返回保留原图"），
 * 本区域仅作为 ImageProcessingService 的采样偏移使用。
 */
export class CropRect {
  readonly x: number
  readonly y: number
  readonly width: number
  readonly height: number

  constructor(x: number, y: number, width: number, height: number) {
    this.x = x
    this.y = y
    this.width = width
    this.height = height
  }

  /**
   * 校验剪裁区域是否可用于采样（尺寸为正且坐标非负）。
   * @param x 左上角横坐标（像素）
   * @param y 左上角纵坐标（像素）
   * @param width 区域宽（像素）
   * @param height 区域高（像素）
   * @returns 区域有效时返回 true
   */
  static isValid(x: number, y: number, width: number, height: number): boolean {
    return Number.isFinite(x) && Number.isFinite(y) &&
      Number.isFinite(width) && Number.isFinite(height) &&
      x >= 0 && y >= 0 && width >= 1 && height >= 1
  }
}
