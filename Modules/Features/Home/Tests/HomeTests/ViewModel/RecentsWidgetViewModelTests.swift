import MEGASwift
import Testing
@testable import Home

@Suite("RecentsWidgetViewModelTests")
@MainActor
struct RecentsWidgetViewModelTests {
    @Test("retry enters loading state before applying the refreshed result")
    func retryEntersLoadingStateBeforeApplyingRefreshedResult() async {
        let useCase = MockRecentsActionsStatesUseCase()
        let sut = RecentsWidgetViewModel(recentsActionsStatesUseCase: useCase)

        let task = Task {
            await sut.didTapRetryButton()
        }

        await Task.yield()

        guard case .loading = sut.state else {
            Issue.record("Expected loading state before the retry finishes")
            return
        }

        useCase.resume(with: .error)
        await task.value

        guard case .error = sut.state else {
            Issue.record("Expected error state after retry finishes")
            return
        }
    }

    @Test("initial state is hidden before onTask completes")
    func initialStateIsHiddenBeforeOnTaskCompletes() async {
        let useCase = MockRecentsActionsStatesUseCase()
        let sut = RecentsWidgetViewModel(recentsActionsStatesUseCase: useCase)

        guard case .hidden = sut.state else {
            Issue.record("Expected hidden as the initial state")
            return
        }

        let task = Task {
            await sut.onTask()
        }

        await useCase.waitForContinuation()
        useCase.resume(with: .empty)

        await Task.yield()
        task.cancel()

        guard case .empty = sut.state else {
            Issue.record("Expected empty state after onTask finishes")
            return
        }
    }
}

private final class MockRecentsActionsStatesUseCase: RecentsActionsStatesUseCaseProtocol, @unchecked Sendable {
    private var continuation: CheckedContinuation<RecentWidgetUseCaseState, Never>?
    private var bufferedState: RecentWidgetUseCaseState?
    private var continuationWaiters: [CheckedContinuation<Void, Never>] = []

    var states: AnyAsyncSequence<RecentWidgetUseCaseState> {
        AsyncStream<RecentWidgetUseCaseState> { _ in }.eraseToAnyAsyncSequence()
    }

    func getLatestBucketState() async -> RecentWidgetUseCaseState {
        if let bufferedState {
            self.bufferedState = nil
            return bufferedState
        }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            let waiters = self.continuationWaiters
            self.continuationWaiters = []
            waiters.forEach { $0.resume() }
        }
    }

    func waitForContinuation() async {
        if continuation != nil { return }
        await withCheckedContinuation { waiter in
            continuationWaiters.append(waiter)
        }
    }

    func resume(with state: RecentWidgetUseCaseState) {
        if let continuation {
            self.continuation = nil
            continuation.resume(returning: state)
        } else {
            bufferedState = state
        }
    }
}
