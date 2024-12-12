import MEGADomain
import MEGASdk
import MEGASwift

public final class FetchNodesRepository: FetchNodesRepositoryProtocol {
    public static var newRepo: FetchNodesRepository {
        FetchNodesRepository(sdk: .sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func fetchNodes() throws -> AnyAsyncSequence<RequestEventEntity> {
        AsyncThrowingStream(RequestEventEntity.self) { continuation in
            let delegate = FetchNodeDelegate { result in
                switch result {
                case .success(let requestEntity):
                    continuation.yield(.finish(requestEntity))
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }
            }
            
            delegate.onStart = { requestEntity in
                continuation.yield(.start(requestEntity))
            }
            
            delegate.onFetching = { requestEntity in
                continuation.yield(.update(requestEntity))
            }
            
            delegate.onTemporaryError = { requestEntity, waitingReason in
                continuation.yield(.temporaryError(requestEntity, waitingReason))
            }
            
            sdk.fetchNodes(with: delegate)
        }.eraseToAnyAsyncSequence()
    }
}
