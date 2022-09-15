import UIKit

public struct SlideShowMediaEntity {
    public var image: UIImage?
    public var node: NodeEntity
    
    public init(image: UIImage?, node: NodeEntity) {
        self.image = image
        self.node = node
    }
}
