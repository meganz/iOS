@testable import Accounts
import Combine
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import Testing

@MainActor
@Suite("App loading view model tests")
struct AppLoadingViewModelTests {
    
    private let events = [EventEntity(number: 500)]
    
    private func makeSUT(
        appLoadingUseCase: AppLoadingUseCaseMock = AppLoadingUseCaseMock(),
        requestStatProgressUseCase: MockRequestStatProgressUseCase = MockRequestStatProgressUseCase(),
        appLoadComplete: ( @Sendable () -> Void)? = nil
    ) -> AppLoadingViewModel {
        AppLoadingViewModel(
            appLoadingUseCase: appLoadingUseCase,
            requestStatProgressUseCase: requestStatProgressUseCase,
            appLoadComplete: appLoadComplete
        )
    }
    
    @Test("Test initial state is initialized")
    func testInitialState() async {
        let viewModel = makeSUT()
        
        #expect(viewModel.status == .initialized)
        #expect(viewModel.statusText == Strings.Localizable.Login.connectingToServer)
        #expect(viewModel.progress == nil)
    }
}

// Mock classes
final class AppLoadingUseCaseMock: AppLoadingUseCaseProtocol, @unchecked Sendable {
    var appLoadingStartUpdates: AnyAsyncSequence<RequestEntity> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    var appLoadingUpdates: AnyAsyncSequence<RequestEntity> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    var appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    var appLoadingFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    
    var waitingReason: WaitingReasonEntity = .apiLock
}
