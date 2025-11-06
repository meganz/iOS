import MEGADomain
import MEGASwift

public protocol AppLoadingUseCaseProtocol: Sendable {
    var appLoadingStartUpdates: AnyAsyncSequence<RequestEntity> { get }
    var appLoadingUpdates: AnyAsyncSequence<RequestEntity> { get }
    var appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Void> { get }
    var appLoadingFinishUpdates: AnyAsyncSequence<Void> { get }
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
    
    /// if error is tryAgain, reqStats with progress appear, we don't need to display the reason
    var appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Void> {
        requestStatesRepository.requestTemporaryErrorUpdates
            .compactMap { $0.error.type == .tryAgain ? nil : () }
            .eraseToAnyAsyncSequence()
    }
    
    var appLoadingFinishUpdates: AnyAsyncSequence<Void> {
        requestStatesRepository
            .completedRequestUpdates
            .compactMap { $0.type == .fetchNodes ? () : nil }
            .eraseToAnyAsyncSequence()
    }
}
