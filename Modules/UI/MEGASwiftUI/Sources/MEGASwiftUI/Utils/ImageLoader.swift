import Combine
import MEGAFoundation
import SwiftUI

public final class ImageLoader: ObservableObject {
    private var cache: NSCache<NSURL, UIImage>
    private var session: any URLSessionProtocol
    
    public init(session: any URLSessionProtocol = URLSession.shared, cache: NSCache<NSURL, UIImage> = NSCache<NSURL, UIImage>()) {
        self.session = session
        self.cache = cache
    }
    
    deinit {
        clearCache()
    }
    
    public func loadImage(from url: URL) async -> UIImage? {
        if let cachedImage = cache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        do {
            let (data, _) = try await session.fetchData(from: url)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: url as NSURL)
                return image
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func clearCache() {
        cache.removeAllObjects()
    }
}
