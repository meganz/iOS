import Foundation
import MEGADomain

final actor PhotosInMemoryCache: PhotoSourceProtocol {
    public static let shared = PhotosInMemoryCache()
    
    private let cache = NSCache<NSNumber, PhotoNodeEntityEntryProxy>()
    private let nodeHandleTracker = CacheIdTracker<PhotoNodeEntityEntryProxy>()
    
    public var photos: [NodeEntity] {
        nodeHandleTracker.identifiers
            .compactMap {
                photo(forHandle: $0)
            }
    }
    
    private init() {
        cache.delegate = nodeHandleTracker
    }
    
    func setPhotos(_ photos: [NodeEntity]) {
        photos.forEach { photo in
            cache[photo.handle] = photo
            nodeHandleTracker.$identifiers.mutate { $0.insert(photo.handle) }
        }
    }

    func photo(forHandle handle: HandleEntity) -> NodeEntity? {
        cache[handle]
    }

    func removePhoto(forHandle handle: HandleEntity) {
        cache[handle] = nil
    }
    
    func removeAllPhotos() {
        cache.removeAllObjects()
    }
}

/// `PhotoNodeEntityCacheEntryProxy` class wrapper thats stored in `NSCache`
private final class PhotoNodeEntityEntryProxy {
    let node: NodeEntity
    init(node: NodeEntity) { self.node = node }
}

extension PhotoNodeEntityEntryProxy: Identifiable {
    var id: HandleEntity { node.handle }
}

private extension NSCache where KeyType == NSNumber, ObjectType == PhotoNodeEntityEntryProxy {
    subscript(_ handle: HandleEntity) -> NodeEntity? {
        get {
            object(forKey: NSNumber(value: handle))?.node
        }
        set {
            let key = NSNumber(value: handle)
            if let entry = newValue {
                let value = PhotoNodeEntityEntryProxy(node: entry)
                setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}
