import SwiftUI

public class ImageContainer {
    public let image: Image
    public var isPlaceholder = false
    
    public init(image: Image, isPlaceholder: Bool = false) {
        self.image = image
        self.isPlaceholder = isPlaceholder
    }
    
    public convenience init?(image: Image?, isPlaceholder: Bool = false) {
        guard let image = image else {
            return nil
        }
        
        self.init(image: image, isPlaceholder: isPlaceholder)
    }
    
    func isEqual(to container: ImageContainer) -> Bool {
        image == container.image && isPlaceholder == container.isPlaceholder
    }
}

extension ImageContainer: Equatable {
    public static func == (lhs: ImageContainer, rhs: ImageContainer) -> Bool {
        lhs.isEqual(to: rhs)
    }
}

public final class URLImageContainer: ImageContainer {
    public let imageURL: URL
    
    public init?(imageURL: URL, isPlaceholder: Bool = false) {
        guard let image = Image(contentsOfFile: imageURL.path) else {
            return nil
        }
        
        self.imageURL = imageURL
        super.init(image: image, isPlaceholder: isPlaceholder)
    }
    
    override func isEqual(to container: ImageContainer) -> Bool {
        guard let container = container as? URLImageContainer else {
            return false
        }
        
        return imageURL == container.imageURL && isPlaceholder == container.isPlaceholder
    }
}
