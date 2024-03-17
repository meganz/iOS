import MEGADomain
import MEGASwift

public actor MockPhotosRepository: PhotosRepositoryProtocol {
    
    public static var sharedRepo: MockPhotosRepository = MockPhotosRepository()
    
    private let photosUpdated: AnyAsyncSequence<[NodeEntity]>
    private let photos: [NodeEntity]
    private var allPhotosCallOrderResult: [Result<[NodeEntity], Error>]
    
    public init(photosUpdated: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence(),
                photos: [NodeEntity] = [],
                allPhotosCallOrderResult: [Result<[NodeEntity], Error>] = []
    ) {
        
        self.photosUpdated = photosUpdated
        self.photos = photos
        self.allPhotosCallOrderResult = allPhotosCallOrderResult
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        guard allPhotosCallOrderResult.isNotEmpty else {
            return photos
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: allPhotosCallOrderResult.removeFirst())
        }
    }
    
    public func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]> {
        photosUpdated
    }
    
    public func photo(forHandle handle: HandleEntity) async -> NodeEntity? {
        photos.first(where: { $0.handle == handle })
    }
}
