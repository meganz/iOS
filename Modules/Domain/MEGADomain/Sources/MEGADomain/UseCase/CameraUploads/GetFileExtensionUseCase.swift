import AVFoundation
import CoreServices
import Foundation
import MEGASwift

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
        guard let uti, let utiType = UTType(uti) else { return nil }

        switch utiType {
        case UTType.jpeg:
            return FileExtensionEntity.jpg.rawValue
        case UTType.heic:
            return FileExtensionEntity.heic.rawValue
        case UTType.heif:
            return FileExtensionEntity.heif.rawValue
        case UTType(AVFileType.dng.rawValue):
            return FileExtensionEntity.dng.rawValue
        case UTType.png:
            return FileExtensionEntity.png.rawValue
        case UTType.quickTimeMovie:
            return FileExtensionEntity.mov.rawValue
        case UTType.mpeg4Movie:
            return FileExtensionEntity.mp4.rawValue
        case UTType.gif:
            return FileExtensionEntity.gif.rawValue
        case UTType.webP:
            return FileExtensionEntity.webp.rawValue
        default:
            return nil
        }
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
