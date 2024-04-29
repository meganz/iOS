import Foundation
import MEGADomain
import MEGASwift

public final class MockMediaUseCase: MediaUseCaseProtocol, @unchecked Sendable {
    private let isURLVideo: Bool
    private let isURLImage: Bool
    @Atomic public var isStringVideoToReturn = false
    private let isStringImage: Bool
    private let isRawImage: Bool
    private let isGifImage: Bool
    private let imageFileNames: [String]?
    private let videoFileNames: [String]?
    private let rawImageFiles: [FileNameEntity]?
    private let gifImageFiles: [FileNameEntity]?
    private let multimediaNodeNames: [String]
    private let isPlayable: Bool
    private let isMediaFile: Bool
    private let isPlayableMediaFile: Bool
    private let allPhotos: [NodeEntity]
    private let allVideos: [NodeEntity]
    
    public private(set) var messages = [Message]()
    
    public enum Message: Equatable {
        case allVideos
    }
    
    public init(isURLVideo: Bool = false,
                isURLImage: Bool = false,
                isStringVideo: Bool = false,
                isStringImage: Bool = false,
                isRawImage: Bool = false,
                isGifImage: Bool = false,
                imageFileNames: [FileNameEntity]? = nil,
                videoFileNames: [FileNameEntity]? = nil,
                rawImageFiles: [FileNameEntity]? = nil,
                gifImageFiles: [FileNameEntity]? = nil,
                multimediaNodeNames: [String] = [],
                isPlayable: Bool = false,
                isMediaFile: Bool = false,
                isPlayableMediaFile: Bool = false,
                allPhotos: [NodeEntity] = [],
                allVideos: [NodeEntity] = []) {
        self.isURLVideo = isURLVideo
        self.isURLImage = isURLImage
        self.isStringImage = isStringImage
        self.isRawImage = isRawImage
        self.isGifImage = isGifImage
        self.imageFileNames = imageFileNames
        self.videoFileNames = videoFileNames
        self.rawImageFiles = rawImageFiles
        self.gifImageFiles = gifImageFiles
        self.multimediaNodeNames = multimediaNodeNames
        self.isPlayable = isPlayable
        self.isMediaFile = isMediaFile
        self.isPlayableMediaFile = isPlayableMediaFile
        self.allPhotos = allPhotos
        self.allVideos = allVideos
        $isStringVideoToReturn.mutate { $0 = isStringVideo }
    }
    
    public func isVideo(for url: URL) -> Bool {
        isURLVideo
    }
    
    public func isImage(for url: URL) -> Bool {
        isURLImage
    }
    
    public func isVideo(_ name: FileNameEntity) -> Bool {
        videoFileNames?.contains(name) ?? isStringVideoToReturn
    }
    
    public func isImage(_ name: FileNameEntity) -> Bool {
        imageFileNames?.contains(name) ?? isStringImage
    }
    
    public func isRawImage(_ name: FileNameEntity) -> Bool {
        rawImageFiles?.contains(name) ?? isRawImage
    }
    
    public func isGifImage(_ name: FileNameEntity) -> Bool {
        gifImageFiles?.contains(name) ?? isGifImage
    }
    
    public func isMultimedia(_ name: FileNameEntity) -> Bool {
        multimediaNodeNames.contains(where: {$0 == name})
    }
    
    public func isPlayable(_ node: NodeEntity) -> Bool {
        isPlayable
    }
    
    public func isMediaFile(_ node: MEGADomain.NodeEntity) -> Bool {
        isMediaFile
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        allPhotos
    }
    
    public func allVideos() async throws -> [NodeEntity] {
        messages.append(.allVideos)
        return allVideos
    }
    
    public func isPlayableMediaFile(_ node: NodeEntity) -> Bool {
        isPlayableMediaFile
    }
}
