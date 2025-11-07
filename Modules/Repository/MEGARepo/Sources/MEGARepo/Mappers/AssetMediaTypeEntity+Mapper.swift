import MEGADomain
import UniformTypeIdentifiers

extension UTType {
    func toAssetMediaFormatEntity() -> AssetMediaFormatEntity {
        if conforms(to: .jpeg) { return .jpeg }
        if conforms(to: .heic) { return .heic }
        if conforms(to: .heif) { return .heif }
        if conforms(to: .png) { return .png }
        if conforms(to: .rawImage) { return .dng }
        if conforms(to: .gif) { return .gif }
        if conforms(to: .webP) { return .webp }
        if conforms(to: .mpeg4Movie) { return .mp4 }
        if conforms(to: .quickTimeMovie) { return .mov }
        
        return .unknown(identifier: preferredFilenameExtension ?? identifier)
    }
}
