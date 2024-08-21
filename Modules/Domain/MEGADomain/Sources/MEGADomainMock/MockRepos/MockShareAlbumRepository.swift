import MEGADomain

public final class MockShareAlbumRepository: ShareAlbumRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockShareAlbumRepository()
    private let shareAlbumResults: [HandleEntity: Result<String?, Error>]
    private let disableAlbumShareResult: Result<Void, Error>
    private let publicAlbumContentsResult: Result<SharedCollectionEntity, Error>
    private let publicPhotoResults: [HandleEntity: Result<NodeEntity, Error>]
    private let copyPublicPhotosResult: Result<[NodeEntity], Error>
    
    public private(set) var stopAlbumLinkPreviewCalled = 0
    
    public init(
        shareAlbumResults: [HandleEntity: Result<String?, Error>] = [:],
        disableAlbumShareResult: Result<Void, Error> = .failure(GenericErrorEntity()),
        publicAlbumContentsResult: Result<SharedCollectionEntity, Error> = .failure(GenericErrorEntity()),
        publicPhotoResults: [HandleEntity: Result<NodeEntity, Error>] = [:],
        copyPublicPhotosResult: Result<[NodeEntity], Error> = .failure(GenericErrorEntity())
    ) {
        self.shareAlbumResults = shareAlbumResults
        self.disableAlbumShareResult = disableAlbumShareResult
        self.publicAlbumContentsResult = publicAlbumContentsResult
        self.publicPhotoResults = publicPhotoResults
        self.copyPublicPhotosResult = copyPublicPhotosResult
    }
    
    public func shareAlbumLink(_ album: AlbumEntity) async throws -> String? {
        guard let shareAlbumResult = shareAlbumResults.first(where: { $0.key == album.id })?.value else {
            return nil
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: shareAlbumResult)
        }
    }
    
    public func removeSharedLink(forAlbumId id: HandleEntity) async throws {
        try await withCheckedThrowingContinuation {
            $0.resume(with: disableAlbumShareResult)
        }
    }
    
    public func publicAlbumContents(forLink link: String) async throws -> SharedCollectionEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicAlbumContentsResult)
        }
    }
    
    public func stopAlbumLinkPreview() {
        stopAlbumLinkPreviewCalled  += 1
    }
    
    public func publicPhoto(_ element: SetElementEntity) async throws -> NodeEntity? {
        guard let publicPhotoResult = publicPhotoResults.first(where: { $0.key == element.id })?.value else {
            return nil
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: publicPhotoResult)
        }
    }
    
    public func copyPublicPhotos(toFolder folder: NodeEntity, photos: [NodeEntity]) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: copyPublicPhotosResult)
        }
    }
}
