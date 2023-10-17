import MEGADomain
@testable import MEGASDKRepo

public actor MockUserAlbumCache: UserAlbumCacheProtocol {
    public var albums: [SetEntity] {
        Array(_albums.values)
    }
    
    private var _albums: [HandleEntity: SetEntity]
    
    public init(albums: [SetEntity] = []) {
        _albums = Dictionary(uniqueKeysWithValues: albums.map { ($0.handle, $0) })
    }
    
    public func setAlbums(_ albums: [SetEntity]) {
        albums.forEach {
            setAlbum($0)
        }
    }
    
    public func setAlbum(_ set: SetEntity) {
        _albums[set.id] = set
    }
    
    public func album(forHandle handle: MEGADomain.HandleEntity) -> SetEntity? {
        _albums[handle]
    }
    
    public func removeAllCachedValues() {
        _albums.removeAll()
    }
}
