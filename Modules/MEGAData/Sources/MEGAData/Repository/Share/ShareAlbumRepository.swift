import MEGADomain
import MEGASdk
import MEGASwift

public struct ShareAlbumRepository: ShareAlbumRepositoryProtocol {
    public static var newRepo = ShareAlbumRepository(sdk: MEGASdk.sharedSdk)
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func shareAlbum(by id: HandleEntity) async throws -> String? {
        try await withAsyncThrowingValue(in: { completion in
            sdk.exportSet(id, delegate: RequestDelegate { result in
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
    
    public func disableAlbumShare(by id: HandleEntity) async throws {
        try await withAsyncThrowingValue(in: { completion in
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
        })
    }
    
    public func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity {
        try await withAsyncThrowingValue(in: { completion in
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
        })
    }
}

