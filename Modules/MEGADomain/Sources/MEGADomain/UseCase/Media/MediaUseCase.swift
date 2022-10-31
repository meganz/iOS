import Foundation

public typealias FileNameEntity = String

public protocol MediaUseCaseProtocol {
    func isVideo(for url: URL) -> Bool
    func isImage(for url: URL) -> Bool
    func isVideo(_ name: FileNameEntity) -> Bool
    func isImage(_ name: FileNameEntity) -> Bool
}

public struct MediaUseCase: MediaUseCaseProtocol {
    public init () {}
    
    public func isVideo(for url: URL) -> Bool {
        VideoFileExtensionEntity().videoSupportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    public func isImage(for url: URL) -> Bool {
        ImageFileExtensionEntity().imagesSupportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    public func isVideo(_ name: FileNameEntity) -> Bool {
        let url = URL(fileURLWithPath: name)
        return isVideo(for: url)
    }
    
    public func isImage(_ name: FileNameEntity) -> Bool {
        let url = URL(fileURLWithPath: name)
        return isImage(for: url)
    }
}
