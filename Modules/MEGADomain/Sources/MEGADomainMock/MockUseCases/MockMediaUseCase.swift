import Foundation
import MEGADomain

public struct MockMediaUseCase: MediaUseCaseProtocol {
    private let isURLVideo: Bool
    private let isURLImage: Bool
    private let isStringVideo: Bool
    private let isStringImage: Bool
    private let isRawImage: Bool
    private let isGifImage: Bool
    
    public init(isURLVideo: Bool = false,
                isURLImage: Bool = false,
                isStringVideo: Bool = false,
                isStringImage: Bool = false,
                isRawImage: Bool = false,
                isGifImage: Bool = false) {
        self.isURLVideo = isURLVideo
        self.isURLImage = isURLImage
        self.isStringVideo = isStringVideo
        self.isStringImage = isStringImage
        self.isRawImage = isRawImage
        self.isGifImage = isGifImage
    }
    
    public func isVideo(for url: URL) -> Bool {
        isURLVideo
    }
    
    public func isImage(for url: URL) -> Bool {
        isURLImage
    }
    
    public func isVideo(_ name: FileNameEntity) -> Bool {
        isStringVideo
    }
    
    public func isImage(_ name: FileNameEntity) -> Bool {
        isStringImage
    }
    
    public func isRawImage(_ name: FileNameEntity) -> Bool {
        isRawImage
    }
    
    public func isGifImage(_ name: FileNameEntity) -> Bool {
        isGifImage
    }
}
