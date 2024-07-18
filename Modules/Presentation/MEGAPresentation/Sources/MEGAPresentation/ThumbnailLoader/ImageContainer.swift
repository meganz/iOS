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

public protocol SensitiveImageContaining: ImageContaining {
    var isSensitive: Bool { get }
}

public struct ImageContainer: ImageContaining, Sendable {
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

public struct URLImageContainer: ImageContaining, Sendable {
    public let imageURL: URL
    public let image: Image
    public let type: ImageType
    
    public init?(imageURL: URL, type: ImageType) {
        guard let uiImage = UIImage(contentsOfFile: imageURL.path) else {
            return nil
        }

        self.imageURL = imageURL
        self.image = Image(uiImage: uiImage)
        self.type = type
    }
    
    public static func == (lhs: URLImageContainer, rhs: URLImageContainer) -> Bool {
        lhs.imageURL == rhs.imageURL && lhs.type == rhs.type
    }
}

public struct SensitiveImageContainer: SensitiveImageContaining {
    public let image: Image
    public let type: ImageType
    public let isSensitive: Bool
    
    public init(image: Image, type: ImageType, isSensitive: Bool) {
        self.image = image
        self.type = type
        self.isSensitive = isSensitive
    }
}

public extension ImageContaining {
    func toSensitiveImageContaining(isSensitive: Bool) -> some SensitiveImageContaining {
        SensitiveImageContainer(image: image,
                                type: type,
                                isSensitive: isSensitive)
    }
}
