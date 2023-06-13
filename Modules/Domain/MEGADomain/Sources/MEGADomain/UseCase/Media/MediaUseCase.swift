import Foundation
import MEGASwift

public typealias FileNameEntity = String

public protocol MediaUseCaseProtocol {
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
    private let fileSearchRepo: any FilesSearchRepositoryProtocol
    private let videoMediaUseCase: (any VideoMediaUseCaseProtocol)?
    
    public init(fileSearchRepo: any FilesSearchRepositoryProtocol, videoMediaUseCase: (any VideoMediaUseCaseProtocol)? = nil) {
        self.fileSearchRepo = fileSearchRepo
        self.videoMediaUseCase = videoMediaUseCase
    }
    
    public func isVideo(_ name: FileNameEntity) -> Bool {
        VideoFileExtensionEntity().videoSupportedExtensions.contains(name.pathExtension)
    }
    
    public func isImage(_ name: FileNameEntity) -> Bool {
        ImageFileExtensionEntity().imagesSupportedExtensions.contains(name.pathExtension) ||
        RawImageFileExtensionEntity().imagesSupportedExtensions.contains(name.pathExtension)
    }
    
    public func isRawImage(_ name: FileNameEntity) -> Bool {
        RawImageFileExtensionEntity().imagesSupportedExtensions.contains(name.pathExtension)
    }
    
    public func isGifImage(_ name: FileNameEntity) -> Bool {
        name.pathExtension == FileExtensionEntity.gif.rawValue
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
