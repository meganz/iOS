import Combine
import MEGAFoundation
import SwiftUI

public protocol ImageLoadingProtocol {
    func loadImage(from url: URL) async -> UIImage?
    func clearCache()
}

public final class ImageLoader: ObservableObject, ImageLoadingProtocol {
    private var cache: NSCache<NSString, UIImage>
    private var session: any URLSessionProtocol
    private var itemCachedCount: Int = 0
    
    public var isCacheClear: Bool {
        itemCachedCount == 0
    }
    
    public init(session: any URLSessionProtocol = URLSession.shared, cache: NSCache<NSString, UIImage> = NSCache<NSString, UIImage>()) {
        self.session = session
        self.cache = cache
    }
    
    public func loadImage(from url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        do {
            let (data, _) = try await session.fetchData(from: url)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: cacheKey)
                itemCachedCount += 1
                return image
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    public func clearCache() {
        cache.removeAllObjects()
        itemCachedCount = 0
    }
}
