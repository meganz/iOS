import Foundation
import MEGADomain

protocol UserAlbumCacheProtocol: Actor {
    var albums: [SetEntity] { get }
    func setAlbums(_ albums: [SetEntity])
    func album(forHandle handle: HandleEntity) -> SetEntity?
    func removeAllCachedValues()
}

actor UserAlbumCache: UserAlbumCacheProtocol {
    static let shared = UserAlbumCache()
    
    private let albumCache = NSCache<NSNumber, SetEntityEntryProxy>()
    private let albumIdTracker = CacheIdTracker<SetEntityEntryProxy>()
    
    var albums: [SetEntity] {
        albumIdTracker.identifiers.compactMap {
            album(forHandle: $0)
        }
    }
    
    private init() {
        albumCache.delegate = albumIdTracker
    }
    
    func setAlbums(_ albums: [SetEntity]) {
        albums.forEach { album in
            albumCache[album.id] = album
            albumIdTracker.$identifiers.mutate { $0.insert(album.id) }
        }
    }
    
    func album(forHandle handle: HandleEntity) -> SetEntity? {
        albumCache[handle]
    }
    
    func removeAllCachedValues() {
        albumCache.removeAllObjects()
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
