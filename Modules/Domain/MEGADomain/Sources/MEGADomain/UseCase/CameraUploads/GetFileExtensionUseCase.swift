import Foundation
import UniformTypeIdentifiers
import AVFoundation
import CoreServices

public protocol GetFileExtensionUseCaseProtocol {
    func fileExtension(for type: MediaTypeEntity, url: URL?, uti: UTType?) -> FileExtension
    
    func fileExtension(for type: MediaTypeEntity, url: URL?, uniformTypeIdentifier uti: String?) -> FileExtension
}

public struct GetFileExtensionUseCase: GetFileExtensionUseCaseProtocol {
    public init() { }
    
    public func fileExtension(for type: MediaTypeEntity, url: URL?, uti: UTType?) -> FileExtension {
        if let fileExtension = fileExtension(for: url) {
            return fileExtension
        } else if let fileExtension = fileExtension(for: uti) {
            return fileExtension
        }
        
        return fileExtension(for: type)
    }
    
    public func fileExtension(for type: MediaTypeEntity, url: URL?, uniformTypeIdentifier uti: String?) -> FileExtension {
        if let fileExtension = fileExtension(for: url) {
            return fileExtension
        } else if let fileExtension = fileExtension(forUTI: uti) {
            return fileExtension
        }
        
        return fileExtension(for: type)
    }
    
    private func fileExtension(for url: URL?) -> FileExtension? {
        guard let fileExtension = url?.pathExtension, !fileExtension.isEmpty else {
            return nil
        }
        
        return fileExtension
    }
    
    private func fileExtension(forUTI uti: String?) -> FileExtension? {
        guard let uti = uti else { return nil }
        
        let utiCFString = uti as CFString
        if UTTypeConformsTo(utiCFString, AVFileType.jpg as CFString) {
            return FileExtensionEntity.jpg.rawValue
        } else if UTTypeConformsTo(utiCFString, AVFileType.heic as CFString) {
            return FileExtensionEntity.heic.rawValue
        } else if UTTypeConformsTo(utiCFString, AVFileType.heif as CFString) {
            return FileExtensionEntity.heif.rawValue
        } else if UTTypeConformsTo(utiCFString, AVFileType.dng as CFString) {
            return FileExtensionEntity.dng.rawValue
        } else if UTTypeConformsTo(utiCFString, kUTTypePNG) {
            return FileExtensionEntity.png.rawValue
        } else if UTTypeConformsTo(utiCFString, AVFileType.mov as CFString) {
            return FileExtensionEntity.mov.rawValue
        } else if UTTypeConformsTo(utiCFString, AVFileType.mp4 as CFString) {
            return FileExtensionEntity.mp4.rawValue
        } else if UTTypeConformsTo(utiCFString, kUTTypeGIF as CFString) {
            return FileExtensionEntity.gif.rawValue
        } else if UTTypeConformsTo(utiCFString, "org.webmproject.webp" as CFString) {
            return FileExtensionEntity.webp.rawValue
        }
        
        return nil
    }
    
    private func fileExtension(for type: MediaTypeEntity) -> FileExtension {
        switch type {
        case .image:
            return FileExtensionEntity.jpg.rawValue
        case .video:
            return FileExtensionEntity.mov.rawValue
        }
    }
}

extension GetFileExtensionUseCase {
    private func fileExtension(for uti: UTType?) -> FileExtension? {
        guard let uti = uti else { return nil }
        
        if uti.conforms(to: .jpeg) {
            return FileExtensionEntity.jpg.rawValue
        } else if uti.conforms(to: .heic) {
            return FileExtensionEntity.heic.rawValue
        } else if uti.conforms(to: .heif) {
            return FileExtensionEntity.heif.rawValue
        } else if uti.conforms(to: .rawImage) {
            return FileExtensionEntity.dng.rawValue
        } else if uti.conforms(to: .png) {
            return FileExtensionEntity.png.rawValue
        } else if uti.conforms(to: .quickTimeMovie) {
            return FileExtensionEntity.mov.rawValue
        } else if uti.conforms(to: .mpeg4Movie) {
            return FileExtensionEntity.mp4.rawValue
        } else if uti.conforms(to: .gif) {
            return FileExtensionEntity.gif.rawValue
        } else if uti.conforms(to: .webP) {
            return FileExtensionEntity.webp.rawValue
        }

        return uti.preferredFilenameExtension
    }
}
