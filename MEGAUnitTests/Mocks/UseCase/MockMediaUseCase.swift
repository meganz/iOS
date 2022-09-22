import Foundation
import MEGADomain
@testable import MEGA

public struct MockMediaUseCase: MediaUseCaseProtocol {
    public var isURLVideo = false
    public var isURLImage = false
    
    public func isVideo(for url: URL) -> Bool {
        isURLVideo
    }
    
    public func isImage(for url: URL) -> Bool {
        isURLImage
    }
}
