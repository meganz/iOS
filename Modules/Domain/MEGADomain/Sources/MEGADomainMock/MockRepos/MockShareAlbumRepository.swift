import MEGADomain

public struct MockShareAlbumRepository: ShareAlbumRepositoryProtocol {
    public static let newRepo = MockShareAlbumRepository()
    private let shareAlbumResults: [HandleEntity: Result<String?, Error>]
    private let disableAlbumShareResult: Result<Void, Error>
    private let publicAlbumContentsResult: Result<SharedAlbumEntity, Error>
    private let publicPhotoResults: [HandleEntity: Result<NodeEntity, Error>]
    
    public init(
        shareAlbumResults: [HandleEntity: Result<String?, Error>] = [:],
        disableAlbumShareResult: Result<Void, Error> = .failure(GenericErrorEntity()),
        publicAlbumContentsResult: Result<SharedAlbumEntity, Error> = .failure(GenericErrorEntity()),
        publicPhotoResults: [HandleEntity: Result<NodeEntity, Error>] = [:]
    ) {
        self.shareAlbumResults = shareAlbumResults
        self.disableAlbumShareResult = disableAlbumShareResult
        self.publicAlbumContentsResult = publicAlbumContentsResult
        self.publicPhotoResults = publicPhotoResults
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
    
    public func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicAlbumContentsResult)
        }
    }
    
    public func publicPhoto(forPhotoId id: HandleEntity) async throws -> NodeEntity {
        guard let publicPhotoResult = publicPhotoResults.first(where: { $0.key == id })?.value else {
            throw SharedPhotoErrorEntity.photoNotFound
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: publicPhotoResult)
        }
    }
}
