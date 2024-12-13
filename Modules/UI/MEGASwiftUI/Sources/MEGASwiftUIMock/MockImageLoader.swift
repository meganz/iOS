import MEGASwiftUI
import SwiftUI

public final actor MockImageLoader: ImageLoadingProtocol {
    private(set) public var clearCacheCallCount = 0
    private let image: UIImage?
    
    public init(image: UIImage? = nil) {
        self.image = image
    }
    
    public func loadImage(from url: URL) async -> UIImage? {
        image
    }
    
    public func clearCache() {
        clearCacheCallCount += 1
    }
}
