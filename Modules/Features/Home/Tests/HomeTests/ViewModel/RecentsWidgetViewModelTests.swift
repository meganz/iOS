import Foundation
@testable import Home
import MEGASwift
import os
import Testing

@Suite("RecentsWidgetViewModelTests")
@MainActor
struct RecentsWidgetViewModelTests {
    @Test("retry enters loading state before applying the refreshed result")
    func retryEntersLoadingStateBeforeApplyingRefreshedResult() async {
        let useCase = MockRecentsActionsStatesUseCase()
        let sut = makeSUT(recentsActionsStatesUseCase: useCase)

        let task = Task {
            await sut.didTapRetryButton()
        }

        await useCase.waitForContinuation()

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

    @Test("initial state is loading before onTask completes")
    func initialStateIsLoadingBeforeOnTaskCompletes() async {
        let useCase = MockRecentsActionsStatesUseCase()
        let sut = makeSUT(recentsActionsStatesUseCase: useCase)

        guard case .loading = sut.state else {
            Issue.record("Expected loading as the initial state")
            return
        }

        let task = Task {
            await sut.onTask()
        }

        await useCase.waitForContinuation()

        guard case .loading = sut.state else {
            Issue.record("Expected loading state while onTask is still waiting for the first refresh")
            task.cancel()
            await task.value
            return
        }

        var sawInitialLoading = false
        var observedEmpty = false
        for await state in sut.$state.values {
            if !sawInitialLoading {
                sawInitialLoading = true
                useCase.resume(with: .empty)
                continue
            }
            if case .empty = state {
                observedEmpty = true
            }
            break
        }

        guard observedEmpty else {
            Issue.record("Expected empty state after onTask finishes")
            task.cancel()
            await task.value
            return
        }

        task.cancel()
        await task.value
    }

    @Test("initial state is taken from the use case")
    func initialStateIsTakenFromUseCase() {
        let sut = makeSUT(recentsActionsStatesUseCase: MockRecentsActionsStatesUseCase(initialState: .hidden))

        guard case .hidden = sut.state else {
            Issue.record("Expected the use case initial state to seed the view model")
            return
        }
    }

    @Test("showing activity enters loading state before applying the refreshed result")
    func showingActivityEntersLoadingStateBeforeApplyingRefreshedResult() async {
        let useCase = MockRecentsActionsStatesUseCase(initialState: .hidden)
        let sut = makeSUT(recentsActionsStatesUseCase: useCase)

        let task = Task {
            await sut.didTapShowActivityButton()
        }

        await useCase.waitForContinuation()

        guard case .loading = sut.state else {
            Issue.record("Expected loading state before the refresh finishes")
            useCase.resume(with: .empty)
            await task.value
            return
        }

        useCase.resume(with: .empty)
        await task.value

        guard case .empty = sut.state else {
            Issue.record("Expected empty state after showing activity finishes")
            return
        }
    }

    private func makeSUT(
        recentsActionsStatesUseCase: MockRecentsActionsStatesUseCase = MockRecentsActionsStatesUseCase(),
        clearRecentActionHistoryUseCase: MockClearRecentActionHistoryUseCase = MockClearRecentActionHistoryUseCase()
    ) -> RecentsWidgetViewModel {
       RecentsWidgetViewModel(
        recentsActionsStatesUseCase: recentsActionsStatesUseCase,
        clearRecentActionHistoryUseCase: clearRecentActionHistoryUseCase
       )
    }
}

private final class MockRecentsActionsStatesUseCase: RecentsActionsStatesUseCaseProtocol, @unchecked Sendable {
    private struct State {
        var continuation: CheckedContinuation<RecentWidgetUseCaseState, Never>?
        var bufferedState: RecentWidgetUseCaseState?
        var continuationWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    let initialState: RecentWidgetUseCaseState

    init(initialState: RecentWidgetUseCaseState = .loading) {
        self.initialState = initialState
    }

    var states: AnyAsyncSequence<RecentWidgetUseCaseState> {
        AsyncStream<RecentWidgetUseCaseState> { _ in }.eraseToAnyAsyncSequence()
    }

    func getLatestBucketState() async -> RecentWidgetUseCaseState {
        enum Outcome {
            case ready(RecentWidgetUseCaseState)
            case wait(waitersToResume: [CheckedContinuation<Void, Never>])
        }

        return await withCheckedContinuation { continuation in
            let outcome: Outcome = state.withLock { state in
                if let buffered = state.bufferedState {
                    state.bufferedState = nil
                    return .ready(buffered)
                }
                state.continuation = continuation
                let waiters = state.continuationWaiters
                state.continuationWaiters = []
                return .wait(waitersToResume: waiters)
            }

            switch outcome {
            case .ready(let value):
                continuation.resume(returning: value)
            case .wait(let waiters):
                waiters.forEach { $0.resume() }
            }
        }
    }

    func waitForContinuation() async {
        await withCheckedContinuation { waiter in
            let alreadySet: Bool = state.withLock { state in
                if state.continuation != nil {
                    return true
                }
                state.continuationWaiters.append(waiter)
                return false
            }
            if alreadySet {
                waiter.resume()
            }
        }
    }

    func resume(with newState: RecentWidgetUseCaseState) {
        let pending: CheckedContinuation<RecentWidgetUseCaseState, Never>? = state.withLock { state in
            if let continuation = state.continuation {
                state.continuation = nil
                return continuation
            }
            state.bufferedState = newState
            return nil
        }
        pending?.resume(returning: newState)
    }
}
