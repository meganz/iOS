import SwiftUI

public protocol ImageContaining: Equatable {
    var image: Image { get }
    var isPlaceholder: Bool { get }
}

public struct ImageContainer: ImageContaining {
    public let image: Image
    public let isPlaceholder: Bool
    
    public init(image: Image, isPlaceholder: Bool = false) {
        self.image = image
        self.isPlaceholder = isPlaceholder
    }
    
    public init?(image: Image?, isPlaceholder: Bool = false) {
        guard let image = image else {
            return nil
        }
        
        self.init(image: image, isPlaceholder: isPlaceholder)
    }
}

public struct URLImageContainer: ImageContaining {
    public let imageURL: URL
    public let image: Image
    public let isPlaceholder: Bool
    
    public init?(imageURL: URL, isPlaceholder: Bool = false) {
        guard let image = Image(contentsOfFile: imageURL.path) else {
            return nil
        }
        
        self.imageURL = imageURL
        self.image = image
        self.isPlaceholder = isPlaceholder
    }
    
    public static func == (lhs: URLImageContainer, rhs: URLImageContainer) -> Bool {
        lhs.imageURL == rhs.imageURL && lhs.isPlaceholder == rhs.isPlaceholder
    }
}
