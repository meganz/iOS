import Combine
import MEGADomain
import MEGASDKRepo

public actor MockUserAlbumCache: UserAlbumCacheProtocol {
    
    public var albums: [SetEntity] {
        Array(_albums.values)
    }
    
    @Published public var removeAllCachedValuesCalledCount = 0
    public private(set) var wasForcedCleared: Bool
    
    private var _albums: [HandleEntity: SetEntity]
    private var albumsElementIds: [HandleEntity: [AlbumPhotoIdEntity]]
    
    public init(albums: [SetEntity] = [],
                albumsElementIds: [HandleEntity: [AlbumPhotoIdEntity]] = [:],
                wasForcedCleared: Bool = false) {
        _albums = Dictionary(uniqueKeysWithValues: albums.map { ($0.handle, $0) })
        self.albumsElementIds = albumsElementIds
        self.wasForcedCleared = wasForcedCleared
    }
    
    public func setAlbums(_ albums: [SetEntity]) {
        albums.forEach {
            setAlbum($0)
        }
    }
    
    public func setAlbum(_ set: SetEntity) {
        _albums[set.id] = set
    }
    
    public func album(forHandle handle: HandleEntity) -> SetEntity? {
        _albums[handle]
    }
    
    public func albumElementIds(forAlbumId id: HandleEntity) -> [AlbumPhotoIdEntity]? {
        albumsElementIds[id]
    }
    
    public func setAlbumElementIds(forAlbumId id: HandleEntity, elementIds: [AlbumPhotoIdEntity]) {
        albumsElementIds[id] = elementIds
    }
        
    public func removeAllCachedValues(forced: Bool) {
        _albums.removeAll()
        albumsElementIds.removeAll()
        removeAllCachedValuesCalledCount += 1
        wasForcedCleared = forced
    }
    
    public func remove(albums: [SetEntity]) {
        albums.forEach {
            _albums.removeValue(forKey: $0.handle)
            albumsElementIds.removeValue(forKey: $0.handle)
        }
    }
    
    public func removeElements(of albums: any Sequence<HandleEntity>) {
        albums.forEach {
            albumsElementIds.removeValue(forKey: $0)
        }
    }
    
    public func clearForcedFlag() {
        wasForcedCleared = false
    }
}
