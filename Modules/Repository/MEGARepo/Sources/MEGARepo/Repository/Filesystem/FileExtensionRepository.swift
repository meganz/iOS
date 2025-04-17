import Foundation
import MEGADomain
import MEGASwift

public struct FileExtensionRepository: FileExtensionRepositoryProtocol {
    public init() {}
    
    public func isImage(url: URL) -> Bool {
        url.fileExtensionGroup.isImage
    }
    
    public func isVideo(url: URL) -> Bool {
        url.fileExtensionGroup.isVideo
    }
}
