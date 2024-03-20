import Combine
import SwiftUI

public final class ImageLoader: ObservableObject {
    private var cache = NSCache<NSURL, UIImage>()
    private var cancellables: Set<AnyCancellable>
    
    public init(
        cache: NSCache<NSURL, UIImage> = NSCache<NSURL, UIImage>(),
        cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    ) {
        self.cache = cache
        self.cancellables = cancellables
    }
    
    public func loadImage(from url: URL) async -> UIImage? {
        if let cachedImage = cache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        guard let downloadedImage = await downloadImage(url: url) else {
            return nil
        }
        
        cacheImage(downloadedImage, for: url)
        return downloadedImage
    }
    
    private func downloadImage(url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    private func cacheImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
