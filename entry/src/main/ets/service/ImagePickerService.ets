/**
 * ImagePickerService.ets - 图片选择与加载服务
 *
 * 【API】HarmonyOS NEXT API 24
 * photoAccessHelper.PhotoViewPicker → URI → fileIo.openSync → fd →
 * image.createImageSource(fd) → ImageSource.createPixelMap() → PixelMap
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { image } from '@kit.ImageKit'
import { fileIo } from '@kit.CoreFileKit'

export class ImagePickerService {
  private static instance: ImagePickerService | null = null

  static getInstance(): ImagePickerService {
    if (!ImagePickerService.instance) {
      ImagePickerService.instance = new ImagePickerService()
    }
    return ImagePickerService.instance
  }

  private constructor() {
  }

  /**
   * 打开系统相册选择器，返回选中图片 URI。取消时返回 ''
   */
  async pickImage(): Promise<string> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker()
      const pickResult: photoAccessHelper.PhotoSelectResult = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      })
      if (pickResult.photoUris.length > 0) {
        return pickResult.photoUris[0]
      }
      return ''
    } catch (err) {
      return ''
    }
  }

  /**
   * 从 URI 加载 PixelMap（通过文件描述符方式）
   */
  async loadPixelMap(uri: string): Promise<image.PixelMap | null> {
    if (uri === '') {
      return null
    }

    let file: fileIo.File | null = null
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
      const imageSource: image.ImageSource = image.createImageSource(file.fd)
      const pixelMap: image.PixelMap = await imageSource.createPixelMap({
        desiredSize: { width: 2000, height: 2000 }
      })
      return pixelMap
    } catch (err) {
      return null
    } finally {
      if (file !== null) {
        fileIo.closeSync(file)
      }
    }
  }
}
