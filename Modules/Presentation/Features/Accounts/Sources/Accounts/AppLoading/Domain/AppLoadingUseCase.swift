import MEGADomain
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
    
    private let requestStatesRepository: any RequestStatesRepositoryProtocol
    private let appLoadingRepository: any AppLoadingRepositoryProtocol
    
    init(
        requestStatesRepository: some RequestStatesRepositoryProtocol,
        appLoadingRepository: some AppLoadingRepositoryProtocol
    ) {
        self.requestStatesRepository = requestStatesRepository
        self.appLoadingRepository = appLoadingRepository
    }
    
    var appLoadingStartUpdates: AnyAsyncSequence<RequestEntity> {
        requestStatesRepository.requestStartUpdates
            .filter { $0.type == .fetchNodes }
            .eraseToAnyAsyncSequence()
    }
    
    var appLoadingUpdates: AnyAsyncSequence<RequestEntity> {
        requestStatesRepository.requestUpdates
            .filter { $0.type == .login || $0.type == .fetchNodes }
            .eraseToAnyAsyncSequence()
    }
    
    var appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> {
        requestStatesRepository.requestTemporaryErrorUpdates
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
        requestStatesRepository.requestFinishUpdates
    }
}
