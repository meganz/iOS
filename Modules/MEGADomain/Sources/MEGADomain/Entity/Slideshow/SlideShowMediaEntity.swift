import UIKit

public struct SlideShowMediaEntity {
    public var image: UIImage?
    public let node: NodeEntity
    public let fileUrl: URL?
    
    public init(image: UIImage?, node: NodeEntity, fileUrl: URL?) {
        self.image = image
        self.node = node
        self.fileUrl = fileUrl
    }
}
