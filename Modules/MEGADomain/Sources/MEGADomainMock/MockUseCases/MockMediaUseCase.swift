import Foundation
import MEGADomain

public struct MockMediaUseCase: MediaUseCaseProtocol {
    private let isURLVideo: Bool
    private let isURLImage: Bool
    private let isStringVideo: Bool
    private let isStringImage: Bool
    
    public init(isURLVideo: Bool = false,
                isURLImage: Bool = false,
                isStringVideo: Bool = false,
                isStringImage: Bool = false) {
        self.isURLVideo = isURLVideo
        self.isURLImage = isURLImage
        self.isStringVideo = isStringVideo
        self.isStringImage = isStringImage
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
}
