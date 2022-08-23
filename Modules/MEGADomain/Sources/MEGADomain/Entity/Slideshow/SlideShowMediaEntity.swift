import UIKit

public struct SlideShowMediaEntity {
    public let image: UIImage
    public var isPlaceholder = false
    
    public init(image: UIImage, isPlaceholder: Bool = false) {
        self.image = image
        self.isPlaceholder = isPlaceholder
    }
}

public extension SlideShowMediaEntity {
    init?(image: UIImage?, isPlaceholder: Bool = false) {
        guard let image = image else { return nil }
        
        self.init(image: image, isPlaceholder: isPlaceholder)
    }
}
