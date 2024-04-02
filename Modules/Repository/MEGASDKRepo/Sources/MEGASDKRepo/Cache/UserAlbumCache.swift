import Foundation
import MEGADomain

public protocol UserAlbumCacheProtocol: Actor {
    var albums: [SetEntity] { get }
    func setAlbums(_ albums: [SetEntity])
    func album(forHandle handle: HandleEntity) -> SetEntity?
    func albumElementIds(forAlbumId id: HandleEntity) -> [AlbumPhotoIdEntity]?
    func setAlbumElementIds(forAlbumId id: HandleEntity, elementIds: [AlbumPhotoIdEntity])
    func removeAllCachedValues()
    
    ///  Remove the provided SetEntities from the local cache. If the set does  exist in the cache it will be evicted immediately. Else no action will happen.
    /// - Parameter albums: List of set entities to be removed from local cache.
    func remove(albums: [SetEntity])
    
    ///  Remove all SetElements related to the passed in Set HandleEntities. The Set will remain in the cache, but only the sequence of elements linked against the Set will be removed.
    /// - Parameter albums: Sequence of Set/Album handle entities
    func removeElements(of albums: any Sequence<HandleEntity>)
}

public actor UserAlbumCache: UserAlbumCacheProtocol {
    public static let shared = UserAlbumCache()
    
    private let albumCache = NSCache<NSNumber, SetEntityEntryProxy>()
    private let albumIdTracker = CacheIdTracker<SetEntityEntryProxy>()
    private let albumElementIdsCache = NSCache<NSNumber, AlbumPhotoIdsEntityProxy>()
    
    public var albums: [SetEntity] {
        albumIdTracker.identifiers.compactMap {
            album(forHandle: $0)
        }
    }
    
    private init() {
        albumCache.delegate = albumIdTracker
    }
    
    public func setAlbums(_ albums: [SetEntity]) {
        albums.forEach { album in
            albumCache[album.id] = album
            albumIdTracker.$identifiers.mutate { $0.insert(album.id) }
        }
    }
    
    public func album(forHandle handle: HandleEntity) -> SetEntity? {
        albumCache[handle]
    }
    
    public func albumElementIds(forAlbumId id: HandleEntity) -> [AlbumPhotoIdEntity]? {
        albumElementIdsCache[id]
    }
    
    public func setAlbumElementIds(forAlbumId id: HandleEntity, elementIds: [AlbumPhotoIdEntity]) {
        albumElementIdsCache[id] = elementIds
    }

    public func removeAllCachedValues() {
        albumCache.removeAllObjects()
        albumElementIdsCache.removeAllObjects()
    }
    
    public func remove(albums: [SetEntity]) {
        albums.forEach {
            let id = NSNumber(value: $0.id)
            albumCache.removeObject(forKey: id)
            albumElementIdsCache.removeObject(forKey: id)
        }
    }
    
    public func removeElements(of albums: any Sequence<HandleEntity>) {
        albums.forEach {
            albumElementIdsCache.removeObject(forKey: NSNumber(value: $0))
        }
    }
}

private final class SetEntityEntryProxy {
    let `set`: SetEntity
    init(set: SetEntity) { self.set = set }
}

extension SetEntityEntryProxy: Identifiable {
    var id: HandleEntity { `set`.id }
}

private extension NSCache where KeyType == NSNumber, ObjectType == SetEntityEntryProxy {
    subscript(_ handle: HandleEntity) -> SetEntity? {
        get {
            object(forKey: NSNumber(value: handle))?.set
        }
        set {
            let key = NSNumber(value: handle)
            if let entry = newValue {
                let value = SetEntityEntryProxy(set: entry)
                setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}

private final class AlbumPhotoIdsEntityProxy {
    let photoIds: [AlbumPhotoIdEntity]
    init(photoIds: [AlbumPhotoIdEntity]) { self.photoIds = photoIds }
}

private extension NSCache where KeyType == NSNumber, ObjectType == AlbumPhotoIdsEntityProxy {
    subscript(_ handle: HandleEntity) -> [AlbumPhotoIdEntity]? {
        get {
            object(forKey: NSNumber(value: handle))?.photoIds
        }
        set {
            let key = NSNumber(value: handle)
            if let entry = newValue {
                setObject(.init(photoIds: entry), forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}
