import MEGADomain
import MEGASDKRepo

public actor MockPhotoLocalSource: PhotoLocalSourceProtocol {
    public var photos: [NodeEntity]
    
    public init(photos: [NodeEntity] = []) {
        self.photos = photos
    }
    
    public func setPhotos(_ photos: [NodeEntity]) {
        self.photos = photos
    }
    
    public func photo(forHandle handle: HandleEntity) -> NodeEntity? {
        photos.first(where: { $0.handle == handle })
    }
    
    public func removePhoto(forHandle handle: HandleEntity) {
        photos.removeAll(where: { $0.handle == handle })
    }
    
    public func removeAllPhotos() {
        photos.removeAll()
    }
}
