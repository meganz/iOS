import MEGAFoundation
import SwiftUI

public protocol ImageLoadingProtocol: Actor {
    func loadImage(from url: URL) async -> UIImage?
    func clearCache()
}

public actor ImageLoader: ImageLoadingProtocol {
    private let cache = NSCache<NSString, UIImage>()
    private let session: any URLSessionProtocol
    private var itemCachedCount: Int = 0
    private var fetchImageTasks: [URL: Task<(Data, URLResponse), any Error>] = [:]
    
    public var isCacheClear: Bool {
        itemCachedCount == 0
    }
    
    public init(session: some URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    public func loadImage(from url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        do {
            // Fetch image data
            let data = try await fetchImageData(from: url)
            
            // Return and cache image
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: cacheKey)
            itemCachedCount += 1
            return image
        } catch {
            return nil
        }
    }
    
    private func fetchImageData(from url: URL) async throws -> Data {
        if let existingTask = fetchImageTasks[url] {
            // Return data from the existing task
            let (data, _) = try await existingTask.value
            return data
        } else {
            // Create a new task and fetch data
            let task = Task { try await session.fetchData(from: url) }
            fetchImageTasks[url] = task
            let (data, _) = try await task.value
            return data
        }
    }
    
    public func clearCache() {
        cache.removeAllObjects()
        itemCachedCount = 0
        
        fetchImageTasks.values.forEach { $0.cancel() }
        fetchImageTasks.removeAll()
    }
}
