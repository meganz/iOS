import Foundation

typealias FileExtension = String

enum FileExtensionEntity: FileExtension {
    case unknown = ""
    case jpg = "jpg"
    case png = "png"
    case mov = "mov"
    case mp4 = "mp4"
    case dng = "dng"
    case heic = "heic"
    case heif = "heif"
    case webp = "webp"
    case gif = "gif"
}
