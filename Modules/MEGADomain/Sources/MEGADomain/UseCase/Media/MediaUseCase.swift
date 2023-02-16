import Foundation

public typealias FileNameEntity = String

public protocol MediaUseCaseProtocol {
    func isVideo(for url: URL) -> Bool
    func isImage(for url: URL) -> Bool
    func isVideo(_ name: FileNameEntity) -> Bool
    func isImage(_ name: FileNameEntity) -> Bool
    func isRawImage(_ name: FileNameEntity) -> Bool
    func isGifImage(_ name: FileNameEntity) -> Bool
    func isMultimedia(_ name: FileNameEntity) -> Bool
    func isMediaFile(_ node: NodeEntity) -> Bool
    func isPlayableMediaFile(_ node: NodeEntity) -> Bool
    
    func allPhotos() async throws -> [NodeEntity]
    func allVideos() async throws -> [NodeEntity]
}

public struct MediaUseCase: MediaUseCaseProtocol {
    private let fileSearchRepo: FilesSearchRepositoryProtocol
    private let videoMediaUseCase: VideoMediaUseCaseProtocol?
    
    public init(fileSearchRepo: FilesSearchRepositoryProtocol, videoMediaUseCase: VideoMediaUseCaseProtocol? = nil) {
        self.fileSearchRepo = fileSearchRepo
        self.videoMediaUseCase = videoMediaUseCase
    }
    
    public func isVideo(for url: URL) -> Bool {
        VideoFileExtensionEntity().videoSupportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    public func isImage(for url: URL) -> Bool {
        ImageFileExtensionEntity().imagesSupportedExtensions.contains(url.pathExtension.lowercased()) ||
        RawImageFileExtensionEntity().imagesSupportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    public func isVideo(_ name: FileNameEntity) -> Bool {
        let url = URL(fileURLWithPath: name)
        return isVideo(for: url)
    }
    
    public func isImage(_ name: FileNameEntity) -> Bool {
        let url = URL(fileURLWithPath: name)
        return isImage(for: url)
    }
    
    public func isRawImage(_ name: FileNameEntity) -> Bool {
        RawImageFileExtensionEntity().imagesSupportedExtensions.contains(NSString(string: name).pathExtension.lowercased())
    }
    
    public func isGifImage(_ name: FileNameEntity) -> Bool {
        NSString(string: name).pathExtension.lowercased() == FileExtensionEntity.gif.rawValue
    }
    
    public func isMultimedia(_ name: FileNameEntity) -> Bool {
        isImage(name) || isVideo(name)
    }
    
    public func isMediaFile(_ node: NodeEntity) -> Bool {
        node.isFile && isMultimedia(node.name)
    }
    
    public func isPlayableMediaFile(_ node: NodeEntity) -> Bool {
        isMediaFile(node) && (videoMediaUseCase?.isPlayable(node) ?? false)
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        try await fileSearchRepo.search(string: "",
                                        parent: nil,
                                        supportCancel: false,
                                        sortOrderType: .defaultDesc,
                                        formatType: .photo)
    }
    
    public func allVideos() async throws -> [NodeEntity] {
        try await fileSearchRepo.search(string: "",
                                        parent: nil,
                                        supportCancel: false,
                                        sortOrderType: .defaultDesc,
                                        formatType: .video)
    }
}
