import SwiftUI

public enum ImageType: Sendable {
    case placeholder
    case thumbnail
    case preview
    case original
}

public protocol ImageContaining: Equatable, Sendable {
    var image: Image { get }
    var type: ImageType { get }
}

public struct ImageContainer: ImageContaining, @unchecked Sendable {
    public let image: Image
    public let type: ImageType
    
    public init(image: Image, type: ImageType) {
        self.image = image
        self.type = type
    }
    
    public init?(image: Image?, type: ImageType) {
        guard let image = image else {
            return nil
        }
        
        self.init(image: image, type: type)
    }
}

public struct URLImageContainer: ImageContaining, @unchecked Sendable {
    public let imageURL: URL
    public let image: Image
    public let type: ImageType
    
    public init?(imageURL: URL, type: ImageType) {
        guard let image = Image(contentsOfFile: imageURL.path) else {
            return nil
        }
        
        self.imageURL = imageURL
        self.image = image
        self.type = type
    }
    
    public static func == (lhs: URLImageContainer, rhs: URLImageContainer) -> Bool {
        lhs.imageURL == rhs.imageURL && lhs.type == rhs.type
    }
}
