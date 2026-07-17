/**
 * ColorUtils.ets - 颜色计算工具
 *
 * 【职责】
 * 色彩空间转换（Hex↔RGB、RGB→XYZ→Lab）和颜色距离计算（Delta E）。
 * 全部纯函数，无状态、无副作用。
 *
 * 【算法链】
 * Hex → RGB → XYZ（D65）→ Lab → Delta E 76
 * 用于精确颜色匹配：图片像素 RGB → Lab → 遍历调色板 → 返回 Delta E 最小的颜色
 */

// ==================== Hex ↔ RGB ====================

/**
 * 十六进制 → RGB
 * 支持 "#RGB" 短格式和 "#RRGGBB" 标准格式
 */
export function hexToRgb(hex: string): number[] {
  let colorHex: string = hex
  if (colorHex.startsWith('#')) {
    colorHex = colorHex.substring(1)
  }
  if (colorHex.length === 3) {
    colorHex = colorHex[0] + colorHex[0] +
      colorHex[1] + colorHex[1] +
      colorHex[2] + colorHex[2]
  }
  return [
    parseInt(colorHex.substring(0, 2), 16),
    parseInt(colorHex.substring(2, 4), 16),
    parseInt(colorHex.substring(4, 6), 16)
  ]
}

/**
 * RGB → 十六进制
 */
export function rgbToHex(rgb: number[]): string {
  const r: string = clampAndPad(rgb[0])
  const g: string = clampAndPad(rgb[1])
  const b: string = clampAndPad(rgb[2])
  return `#${r}${g}${b}`
}

// ==================== RGB 欧几里得距离（快速匹配） ====================

/**
 * RGB 空间欧几里得距离
 * 用于快速颜色匹配，精度低于 Delta E
 */
export function colorDistanceRgb(a: number[], b: number[]): number {
  const dr: number = a[0] - b[0]
  const dg: number = a[1] - b[1]
  const db: number = a[2] - b[2]
  return Math.sqrt(dr * dr + dg * dg + db * db)
}

// ==================== RGB → XYZ → Lab（精准匹配链） ====================

/**
 * sRGB → XYZ（D65 参考白点）
 *
 * 标准 CIE 转换公式。
 * 先将 sRGB（gamma 2.2）线性化，再通过 D65 转换矩阵得到 XYZ。
 */
export function rgbToXyz(rgb: number[]): number[] {
  // Step 1: sRGB 0-255 → 线性 0-1（gamma 校正）
  const r: number = gammaExpand(rgb[0] / 255.0)
  const g: number = gammaExpand(rgb[1] / 255.0)
  const b: number = gammaExpand(rgb[2] / 255.0)

  // Step 2: 线性 RGB → XYZ（sRGB D65 矩阵）
  const x: number = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
  const y: number = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
  const z: number = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

  return [x, y, z]
}

/**
 * XYZ → CIE Lab（D65 参考白点）
 *
 * 参考白点：D65 = [0.95047, 1.00000, 1.08883]
 */
export function xyzToLab(xyz: number[]): number[] {
  const x: number = xyz[0] / 0.95047
  const y: number = xyz[1] / 1.00000
  const z: number = xyz[2] / 1.08883

  const fx: number = labF(x)
  const fy: number = labF(y)
  const fz: number = labF(z)

  const L: number = 116.0 * fy - 16.0
  const a: number = 500.0 * (fx - fy)
  const b: number = 200.0 * (fy - fz)

  return [L, a, b]
}

/**
 * RGB → Lab（便捷方法，组合 rgbToXyz + xyzToLab）
 */
export function rgbToLab(rgb: number[]): number[] {
  return xyzToLab(rgbToXyz(rgb))
}

// ==================== Delta E 76（CIE76） ====================

/**
 * CIE76 Delta E 色彩距离（Lab 空间欧几里得距离）
 *
 * @param lab1 第一个 Lab 颜色 [L, a, b]
 * @param lab2 第二个 Lab 颜色 [L, a, b]
 * @returns Delta E 值。越小越相近。人眼感知阈值 ≈ 2.3
 *
 * 公式：sqrt((L1-L2)² + (a1-a2)² + (b1-b2)²)
 */
export function deltaE76(lab1: number[], lab2: number[]): number {
  const dL: number = lab1[0] - lab2[0]
  const da: number = lab1[1] - lab2[1]
  const db: number = lab1[2] - lab2[2]
  return Math.sqrt(dL * dL + da * da + db * db)
}

// ==================== 内部辅助函数 ====================

/** sRGB gamma 展开（线性化） */
function gammaExpand(channel: number): number {
  if (channel <= 0.04045) {
    return channel / 12.92
  }
  return Math.pow((channel + 0.055) / 1.055, 2.4)
}

/** Lab 转换辅助函数 */
function labF(t: number): number {
  const delta: number = 6.0 / 29.0
  if (t > delta * delta * delta) {
    return Math.pow(t, 1.0 / 3.0)
  }
  return t / (3.0 * delta * delta) + 4.0 / 29.0
}

/** 钳位并格式化为两位十六进制 */
function clampAndPad(value: number): string {
  const clamped: number = Math.max(0, Math.min(255, Math.round(value)))
  const hex: string = clamped.toString(16)
  return hex.length === 1 ? '0' + hex : hex
}
