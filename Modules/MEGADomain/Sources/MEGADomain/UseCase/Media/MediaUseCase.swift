import Foundation

public protocol MediaUseCaseProtocol {
    func isVideo(for url: URL) -> Bool
    func isImage(for url: URL) -> Bool
}

public struct MediaUseCase: MediaUseCaseProtocol {
    public init () {}
    
    public func isVideo(for url: URL) -> Bool {
        VideoFileExtensionEntity().videoSupportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    public func isImage(for url: URL) -> Bool {
        ImageFileExtensionEntity().imagesSupportedExtensions.contains(url.pathExtension.lowercased())
    }
}


