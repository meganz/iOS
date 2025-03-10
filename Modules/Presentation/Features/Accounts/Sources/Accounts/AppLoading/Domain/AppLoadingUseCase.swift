import MEGADomain
import MEGASDKRepo
import MEGASwift

public protocol AppLoadingUseCaseProtocol: Sendable {
    var appLoadingStartUpdates: AnyAsyncSequence<RequestEntity> { get }
    var appLoadingUpdates: AnyAsyncSequence<RequestEntity> { get }
    var appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> { get }
    var appLoadingFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> { get }
    var waitingReason: WaitingReasonEntity { get }
}

struct AppLoadingUseCase: AppLoadingUseCaseProtocol {
    var waitingReason: WaitingReasonEntity {
        appLoadingRepository.waitingReason
    }
    
    private let requestProvider: any RequestProviderProtocol
    private let appLoadingRepository: any AppLoadingRepositoryProtocol
    
    init(
        requestProvider: some RequestProviderProtocol,
        appLoadingRepository: some AppLoadingRepositoryProtocol
    ) {
        self.requestProvider = requestProvider
        self.appLoadingRepository = appLoadingRepository
    }
    
    var appLoadingStartUpdates: AnyAsyncSequence<RequestEntity> {
        requestProvider.requestStartUpdates
            .filter { $0.type == .fetchNodes }
            .eraseToAnyAsyncSequence()
    }
    
    var appLoadingUpdates: AnyAsyncSequence<RequestEntity> {
        requestProvider.requestUpdates
            .filter { $0.type == .login || $0.type == .fetchNodes }
            .eraseToAnyAsyncSequence()
    }
    
    var appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> {
        requestProvider.requestTemporaryErrorUpdates
            .filter { result in
                if case .failure(let errorEntity) = result {
                    // if error is tryAgain, reqStats with progress appear, we don't need to display the reason
                    return errorEntity.type != .tryAgain
                }
                return false
            }
            .eraseToAnyAsyncSequence()
    }
    
    var appLoadingFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> {
        requestProvider.requestFinishUpdates
    }
}
