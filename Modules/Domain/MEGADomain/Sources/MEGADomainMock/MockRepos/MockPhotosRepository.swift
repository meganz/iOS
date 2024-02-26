import MEGADomain
import MEGASwift

public actor MockPhotosRepository: PhotosRepositoryProtocol {
    
    public static var sharedRepo: MockPhotosRepository = MockPhotosRepository()
    
    private let photosUpdated: AnyAsyncSequence<[NodeEntity]>
    private let photos: [NodeEntity]
    
    public init(photosUpdated: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence(),
                photos: [NodeEntity] = []) {
        self.photosUpdated = photosUpdated
        self.photos = photos
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        photos
    }
 
    public func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]> {
        photosUpdated
    }
    
    public func photo(forHandle handle: HandleEntity) async -> NodeEntity? {
        photos.first(where: { $0.handle == handle })
    }
}
