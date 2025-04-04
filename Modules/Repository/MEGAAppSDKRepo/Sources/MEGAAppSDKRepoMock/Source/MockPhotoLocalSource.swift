import Combine
import MEGAAppSDKRepo
import MEGADomain

public actor MockPhotoLocalSource: PhotoLocalSourceProtocol {
    public var wasForcedCleared: Bool
    
    private var _photos: [HandleEntity: NodeEntity]

    @Published public var removeAllCachedValuesCalledCount = 0
    public private(set) var setPhotosCalledCount = 0

    public var photos: [NodeEntity] {
        Array(_photos.values)
    }
    
    public init(photos: [NodeEntity] = [],
                wasForcedCleared: Bool = false) {
        _photos = Dictionary(uniqueKeysWithValues: photos.map { ($0.handle, $0) })
        self.wasForcedCleared = wasForcedCleared
    }
    
    public func setPhotos(_ photos: [NodeEntity]) {
        setPhotosCalledCount += 1
        photos.forEach {
            _photos[$0.handle] = $0
        }
    }
    
    public func photo(forHandle handle: HandleEntity) -> NodeEntity? {
        _photos[handle]
    }
    
    public func removePhoto(forHandle handle: HandleEntity) {
        _photos[handle] = nil
    }
    
    public func removeAllPhotos(forced: Bool) {
        _photos.removeAll()
        removeAllCachedValuesCalledCount += 1
        wasForcedCleared = forced
    }
    
    public func clearForcedFlag() {
        wasForcedCleared = false
    }
}
