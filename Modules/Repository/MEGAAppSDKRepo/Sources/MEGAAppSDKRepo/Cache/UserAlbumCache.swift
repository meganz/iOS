import Foundation
import MEGADomain

public protocol UserAlbumCacheProtocol: Actor {
    /// Flag to indicate that the cache was forcefully cleared
    /// - Returns: Bool
    var wasForcedCleared: Bool { get }
    var albums: [SetEntity] { get }
    func setAlbums(_ albums: [SetEntity])
    func album(forHandle handle: HandleEntity) -> SetEntity?
    func albumElementIds(forAlbumId id: HandleEntity) -> [AlbumPhotoIdEntity]?
    func setAlbumElementIds(forAlbumId id: HandleEntity, elementIds: [AlbumPhotoIdEntity])
    
    /// Insert the given AlbumPhotoIdEntities to be stored into the local cache.
    /// - Parameter elements: Sequence of AlbumPhotoIdEntity to be stored into the local cache.
    func insert(elements: [AlbumPhotoIdEntity])

    ///  Remove all cached values from the local cache.
    /// - Parameter forced: Flag to indicate that it was forcefully cleared
    func removeAllCachedValues(forced: Bool)
    
    ///  Remove the provided SetEntities from the local cache. If the set does  exist in the cache it will be evicted immediately. Else no action will happen.
    /// - Parameter albums: List of set entities to be removed from local cache.
    func remove(albums: [SetEntity])
    
    ///  Remove all SetElements related to the passed in Set HandleEntities. The Set will remain in the cache, but only the sequence of elements linked against the Set will be removed.
    /// - Parameter albums: Sequence of Set/Album handle entities
    func removeElements(of albums: any Sequence<HandleEntity>)
    
    /// Remove the given AlbumPhotoIdEntities from the local cache in its associated set caches. If the AlbumPhotoIdEntity does not exist no action will be taken for that entity.
    /// - Parameter elements: Sequence of AlbumPhotoIdEntity to be removed stored from the local cache.
    func remove(elements: any Sequence<AlbumPhotoIdEntity>)
    
    /// Clear the forced flag
    func clearForcedFlag()
}

public actor UserAlbumCache: UserAlbumCacheProtocol {
    public static let shared = UserAlbumCache()
    
    public private(set) var wasForcedCleared = false
    
    private var albumCache = [HandleEntity: SetEntity]()
    private var albumElementIdsCache = [HandleEntity: [AlbumPhotoIdEntity]]()
    
    public var albums: [SetEntity] {
        Array(albumCache.values)
    }
    
    private init() {}
    
    public func setAlbums(_ albums: [SetEntity]) {
        albums.forEach { album in
            albumCache[album.id.handle] = album
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
    
    public func insert(elements: [AlbumPhotoIdEntity]) {
        elements.forEach {
            let albumId = $0.albumId
            if albumElementIdsCache[albumId] == nil {
                albumElementIdsCache[albumId] = [$0]
            } else if albumElementIdsCache[albumId]?.notContains($0) == true {
                albumElementIdsCache[albumId]?.append($0)
            }
        }
    }

    public func removeAllCachedValues(forced: Bool) {
        albumCache.removeAll()
        albumElementIdsCache.removeAll()
        wasForcedCleared = forced
    }
    
    public func remove(albums: [SetEntity]) {
        albums.forEach {
            albumCache[$0.id.handle] = nil
            albumElementIdsCache[$0.id.handle] = nil
        }
    }
    
    public func removeElements(of albums: any Sequence<HandleEntity>) {
        albums.forEach {
            albumElementIdsCache[$0] = nil
        }
    }
    public func remove(elements: any Sequence<AlbumPhotoIdEntity>) {
        elements.forEach {
            albumElementIdsCache[$0.albumId]?.remove(object: $0)
        }
    }
    
    public func clearForcedFlag() {
        wasForcedCleared = false
    }
}
