import Combine
import MEGADomain
import MEGASDKRepo

public actor MockPhotoLocalSource: PhotoLocalSourceProtocol {
    private var _photos: [HandleEntity: NodeEntity]

    @Published public var removeAllCachedValuesCalledCount = 0
    public private(set) var setPhotosCalledCount = 0

    public var photos: [NodeEntity] {
        Array(_photos.values)
    }
    
    public init(photos: [NodeEntity] = []) {
        _photos = Dictionary(uniqueKeysWithValues: photos.map { ($0.handle, $0) })
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
    
    public func removeAllPhotos() {
        _photos.removeAll()
        removeAllCachedValuesCalledCount += 1
    }
}
