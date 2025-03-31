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
    let appLoadingStartUpdates: AnyAsyncSequence<RequestEntity>
    let appLoadingUpdates: AnyAsyncSequence<RequestEntity>
    let appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Void>
    let appLoadingFinishUpdates: AnyAsyncSequence<Void>
    
    let waitingReason: WaitingReasonEntity

    init(
        appLoadingStartUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        appLoadingUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        appLoadingTemporaryErrorUpdates: AnyAsyncSequence<Void> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        appLoadingFinishUpdates: AnyAsyncSequence<Void> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        waitingReason: WaitingReasonEntity = .apiLock
    ) {
        self.appLoadingStartUpdates = appLoadingStartUpdates
        self.appLoadingUpdates = appLoadingUpdates
        self.appLoadingTemporaryErrorUpdates = appLoadingTemporaryErrorUpdates
        self.appLoadingFinishUpdates = appLoadingFinishUpdates
        self.waitingReason = waitingReason
    }
}
