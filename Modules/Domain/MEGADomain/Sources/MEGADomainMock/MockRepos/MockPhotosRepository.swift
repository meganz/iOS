import MEGADomain
import MEGASwift

public actor MockPhotosRepository: PhotosRepositoryProtocol {
    
    public static let sharedRepo: MockPhotosRepository = MockPhotosRepository()
    
    private let photosUpdated: AnyAsyncSequence<[NodeEntity]>
    private let photos: [NodeEntity]
    private var allPhotosCallOrderResult: [Result<[NodeEntity], any Error>]
    
    public init(photosUpdated: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence(),
                photos: [NodeEntity] = [],
                allPhotosCallOrderResult: [Result<[NodeEntity], any Error>] = []
    ) {
        self.photosUpdated = photosUpdated
        self.photos = photos
        self.allPhotosCallOrderResult = allPhotosCallOrderResult
    }
    
    public func allPhotos(excludeSensitive: Bool) async throws -> [NodeEntity] {
        if let nextResult = try await nextResult(excludeSensitive: excludeSensitive) {
            nextResult
        } else {
            filterPhotos(photos, excludeSensitive: excludeSensitive)
        }
    }
    
    public func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]> {
        photosUpdated
    }
    
    public func photo(forHandle handle: HandleEntity, excludeSensitive: Bool) async -> NodeEntity? {
        let photo = photos.first(where: { $0.handle == handle })
        if excludeSensitive && photo?.isMarkedSensitive == true {
            return nil
        } else {
            return photo
        }
    }
    
    // MARK: Private
    
    private func nextResult(excludeSensitive: Bool) async throws -> [NodeEntity]? {
        guard allPhotosCallOrderResult.isNotEmpty else { return nil }
        
        return try await withCheckedThrowingContinuation {
            let result = allPhotosCallOrderResult.removeFirst()
            let returnValue = if excludeSensitive {
                result.map { $0.filter { !$0.isMarkedSensitive } }
            } else {
                result
            }
            $0.resume(with: returnValue)
        }
    }
    
    private func filterPhotos(_ photos: [NodeEntity], excludeSensitive: Bool) -> [NodeEntity] {
        return if excludeSensitive {
            photos.filter { !$0.isMarkedSensitive }
        } else {
            photos
        }
    }
}
