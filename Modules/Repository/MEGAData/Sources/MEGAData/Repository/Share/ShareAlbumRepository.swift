import MEGADomain
import MEGASdk
import MEGASwift

public struct ShareAlbumRepository: ShareAlbumRepositoryProtocol {
    public static var newRepo = ShareAlbumRepository(sdk: MEGASdk.sharedSdk)
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func shareAlbumLink(_ album: AlbumEntity) async throws -> String? {
        if album.isLinkShared {
            return sdk.publicLinkForExportedSet(bySid: album.id)
        }
        return try await withAsyncThrowingValue(in: { completion in
            sdk.exportSet(album.id, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.link))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(ShareAlbumErrorEntity.buisinessPastDue))
                    } else {
                        completion(.failure(GenericErrorEntity()))
                    }
                }
            })
        })
    }
    
    public func removeSharedLink(forAlbumId id: HandleEntity) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.disableExportSet(id, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(ShareAlbumErrorEntity.buisinessPastDue))
                    } else {
                        completion(.failure(GenericErrorEntity()))
                    }
                }
            })
        }
    }
    
    public func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity {
        try await withAsyncThrowingValue { completion in
            sdk.fetchPublicSet(link, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    let sharedAlbum = SharedAlbumEntity(set: request.set.toSetEntity(),
                                                        setElements: request.elementsInSet.toSetElementsEntities())
                    completion(.success(sharedAlbum))
                case .failure(let error):
                    let errorEntity: Error
                    switch error.type {
                    case .apiENoent:
                        errorEntity = SharedAlbumErrorEntity.resourceNotFound
                    case .apiEInternal:
                        errorEntity = SharedAlbumErrorEntity.couldNotBeReadOrDecrypted
                    case .apiEArgs:
                        errorEntity = SharedAlbumErrorEntity.malformed
                    case .apiEAccess:
                        errorEntity = SharedAlbumErrorEntity.permissionError
                    default:
                        errorEntity = GenericErrorEntity()
                    }
                    completion(.failure(errorEntity))
                }
            })
        }
    }
    
    public func publicPhoto(forPhotoId id: HandleEntity) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            sdk.previewElementNode(id, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.publicNode.toNodeEntity()))
                case .failure(let error):
                    let errorEntity: Error
                    switch error.type {
                    case .apiEArgs:
                        errorEntity = SharedPhotoErrorEntity.photoNotFound
                    case .apiEAccess:
                        errorEntity = SharedPhotoErrorEntity.previewModeNotEnabled
                    default:
                        errorEntity = GenericErrorEntity()
                    }
                    completion(.failure(errorEntity))
                }
            })
        }
    }
}
