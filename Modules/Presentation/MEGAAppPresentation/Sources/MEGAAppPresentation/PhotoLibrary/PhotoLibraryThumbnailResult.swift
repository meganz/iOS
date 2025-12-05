import UIKit

public struct PhotoLibraryThumbnailResult: Sendable {
    public let image: UIImage
    public let isDegraded: Bool
    
    public init(image: UIImage, isDegraded: Bool) {
        self.image = image
        self.isDegraded = isDegraded
    }
}
