import MEGASwiftUI
import SwiftUI

public final class MockImageLoader: ImageLoadingProtocol {
    public var clearCacheCallCount = 0
    
    public init() {}
    
    public func loadImage(from url: URL) async -> UIImage? { nil }
    public func clearCache() {
        clearCacheCallCount += 1
    }
}
