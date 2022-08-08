import SwiftUI

public struct ImageContainer: Equatable {
    public let image: Image
    public var isPlaceholder = false
    
    public init(image: Image, isPlaceholder: Bool = false) {
        self.image = image
        self.isPlaceholder = isPlaceholder
    }
}

public extension ImageContainer {
    init?(image: Image?, isPlaceholder: Bool = false) {
        guard let image = image else {
            return nil
        }
        
        self.init(image: image, isPlaceholder: isPlaceholder)
    }
}
