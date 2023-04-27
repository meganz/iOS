import MEGADomain

public struct MockShareAlbumRepository: ShareAlbumRepositoryProtocol {
    public static let newRepo = MockShareAlbumRepository()
    private let shareAlbumResult: Result<String?, Error>
    private let disableAlbumShareResult: Result<Void, Error>
    private let publicAlbumContentsResult: Result<SharedAlbumEntity, Error>
    
    public init(shareAlbumResult: Result<String?, Error> = .failure(GenericErrorEntity()),
         disableAlbumShareResult: Result<Void, Error> = .failure(GenericErrorEntity()),
         publicAlbumContentsResult: Result<SharedAlbumEntity, Error> = .failure(GenericErrorEntity())) {
        self.shareAlbumResult = shareAlbumResult
        self.disableAlbumShareResult = disableAlbumShareResult
        self.publicAlbumContentsResult = publicAlbumContentsResult
    }
    
    public func shareAlbum(by id: HandleEntity) async throws -> String? {
        try await withCheckedThrowingContinuation {
            $0.resume(with: shareAlbumResult)
        }
    }
    
    public func disableAlbumShare(by id: HandleEntity) async throws {
        try await withCheckedThrowingContinuation {
            $0.resume(with: disableAlbumShareResult)
        }
    }
    
    public func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicAlbumContentsResult)
        }
    }
}
