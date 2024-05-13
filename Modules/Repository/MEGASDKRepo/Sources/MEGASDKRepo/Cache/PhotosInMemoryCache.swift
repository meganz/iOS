import Foundation
import MEGADomain

public final actor PhotosInMemoryCache: PhotoLocalSourceProtocol {
    public static let shared = PhotosInMemoryCache()
    
    public private(set) var wasForcedCleared = false
    
    private var cache = [HandleEntity: NodeEntity]()
    
    public var photos: [NodeEntity] {
        Array(cache.values)
    }
    
    public func setPhotos(_ photos: [NodeEntity]) {
        photos.forEach {
            cache[$0.handle] = $0
        }
    }

    public func photo(forHandle handle: HandleEntity) -> NodeEntity? {
        cache[handle]
    }

    public func removePhoto(forHandle handle: HandleEntity) {
        cache[handle] = nil
    }
    
    public func removeAllPhotos(forced: Bool) {
        cache.removeAll()
        wasForcedCleared = forced
    }
    
    public func clearForcedFlag() {
        wasForcedCleared = false
    }
}
