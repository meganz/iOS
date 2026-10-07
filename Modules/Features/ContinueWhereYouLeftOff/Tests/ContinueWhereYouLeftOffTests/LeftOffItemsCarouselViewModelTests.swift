import ContinueWhereYouLeftOffMock
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Observation
import Testing
@testable import ContinueWhereYouLeftOff

@Suite("LeftOffItemsCarouselViewModel", .timeLimit(.minutes(1)))
@MainActor
struct LeftOffItemsCarouselViewModelTests {
    private typealias State = LeftOffItemsCarouselViewModel.State

    private final class Gate: @unchecked Sendable {
        private let lock = NSLock()
        private var isOpen = false

        func open() {
            lock.withLock { isOpen = true }
        }

        func wait() async {
            while !lock.withLock({ isOpen }) && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(2))
            }
        }
    }

    private func makeResolved(_ handle: HandleEntity) -> ResolvedLeftOffItemEntity {
        let node = NodeEntity(name: "file\(handle).jpg", handle: handle)
        return ResolvedLeftOffItemEntity(
            item: LeftOffItemEntity(handle: handle, name: node.name, lastAccessed: .now),
            node: node
        )
    }

    private func makeResolvedItems(count: Int) -> [ResolvedLeftOffItemEntity] {
        (0..<count).map { makeResolved(HandleEntity($0 + 1)) }
    }

    private func makeSUT(
        useCase: MockLeftOffItemsUseCase
    ) -> LeftOffItemsCarouselViewModel {
        LeftOffItemsCarouselViewModel(leftOffItemsUseCase: useCase, debounceInterval: .zero)
    }

    private func makeSignals(for useCase: MockLeftOffItemsUseCase) -> AsyncStream<Void>.Continuation {
        let (signals, continuation) = AsyncStream<Void>.makeStream()
        useCase.changesSignalSequenceResult = signals.eraseToAnyAsyncSequence()
        return continuation
    }

    private func start(_ sut: LeftOffItemsCarouselViewModel) -> Task<Void, Never> {
        Task { await sut.onTask() }
    }

    private func stop(_ task: Task<Void, Never>) async {
        task.cancel()
        await task.value
    }

    private func waitForState(of sut: LeftOffItemsCarouselViewModel, matching predicate: (State) -> Bool) async {
        while !predicate(sut.state) {
            try? await Task.sleep(for: .milliseconds(2))
        }
    }

    private final class ChangeCounter: @unchecked Sendable {
        var count = 0
    }

    private static func countStateChanges(of sut: LeftOffItemsCarouselViewModel, into counter: ChangeCounter) {
        withObservationTracking {
            _ = sut.state
        } onChange: {
            counter.count += 1
            Task { @MainActor in
                countStateChanges(of: sut, into: counter)
            }
        }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        while !condition() {
            try? await Task.sleep(for: .milliseconds(2))
        }
    }

    private func loadedParts(_ state: State) -> (items: [LeftOffItemWidgetCardModel], hasMore: Bool, isLoadingMore: Bool)? {
        guard case let .loaded(items, hasMore, isLoadingMore) = state else { return nil }
        return (items, hasMore, isLoadingMore)
    }

    // MARK: - State boundaries

    @Test("it starts in loading")
    func startsLoading() {
        let sut = makeSUT(useCase: MockLeftOffItemsUseCase())

        #expect(sut.state == .loading)
    }

    @Test("zero items gives empty")
    func zeroItemsGivesEmpty() async {
        let sut = makeSUT(useCase: MockLeftOffItemsUseCase())
        let task = start(sut)

        await waitForState(of: sut) { $0 == .empty }

        #expect(sut.state == .empty)
        await stop(task)
    }

    @Test("one item gives loaded")
    func oneItemGivesLoaded() async {
        let sut = makeSUT(useCase: MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 1)))
        let task = start(sut)

        await waitForState(of: sut) { $0 != .loading }

        let parts = loadedParts(sut.state)
        #expect(parts?.items.count == 1)
        #expect(parts?.hasMore == false)
        await stop(task)
    }

    @Test("eight items gives no more tile")
    func eightItemsHasNoMore() async {
        let sut = makeSUT(useCase: MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 8)))
        let task = start(sut)

        await waitForState(of: sut) { $0 != .loading }

        let parts = loadedParts(sut.state)
        #expect(parts?.items.count == 8)
        #expect(parts?.hasMore == false)
        await stop(task)
    }

    @Test("nine items gives eight cards and a more tile")
    func nineItemsHasMore() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 9))
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)

        await waitForState(of: sut) { $0 != .loading }

        let parts = loadedParts(sut.state)
        #expect(parts?.items.count == 8)
        #expect(parts?.hasMore == true)
        #expect(useCase.lastTopLimit == 9)
        await stop(task)
    }

    // MARK: - loadMore

    @Test("loadMore raises the page to sixteen")
    func loadMoreRaisesPage() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 30))
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }

        await sut.loadMore()

        #expect(loadedParts(sut.state)?.items.count == 16)
        #expect(useCase.lastTopLimit == 17)
        #expect(loadedParts(sut.state)?.hasMore == true)
        await stop(task)
    }

    @Test("hasMore becomes false at the store ceiling")
    func hasMoreFalseAtCeiling() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 20))
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }
        await sut.loadMore()
        #expect(loadedParts(sut.state)?.items.count == 16)

        await sut.loadMore()

        #expect(loadedParts(sut.state)?.items.count == 20)
        #expect(loadedParts(sut.state)?.hasMore == false)
        await stop(task)
    }

    @Test("the more tile is disabled while a larger page resolves")
    func moreTileDisabledWhileLoadingMore() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 30))
        let gate = Gate()
        useCase.onTopItems = { call in
            if call == 2 { await gate.wait() }
        }
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }

        let more = Task { await sut.loadMore() }
        await waitUntil { useCase.topItemsCallCount == 2 }

        #expect(loadedParts(sut.state)?.isLoadingMore == true)
        gate.open()
        await more.value
        #expect(loadedParts(sut.state)?.items.count == 16)
        #expect(loadedParts(sut.state)?.isLoadingMore == false)
        await stop(task)
    }

    @Test("a failed more fetch enables the more tile again and keeps the items")
    func failedMoreFetchReenablesTile() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 30))
        useCase.topItemsErrorsPerCall = [nil, .persistenceFailure]
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }

        await sut.loadMore()

        let parts = loadedParts(sut.state)
        #expect(parts?.isLoadingMore == false)
        #expect(parts?.items.count == 8)
        #expect(parts?.hasMore == true)
        await stop(task)
    }

    // MARK: - loadMore race

    @Test("a slower smaller fetch does not shrink the carousel after a more tap")
    func smallerFetchDoesNotShrinkCarousel() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 30))
        let signals = makeSignals(for: useCase)
        let gate = Gate()
        useCase.onTopItems = { call in
            if call == 2 { await gate.wait() }
        }
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }

        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 2 }
        await sut.loadMore()
        #expect(loadedParts(sut.state)?.items.count == 16)

        gate.open()
        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 4 }

        #expect(loadedParts(sut.state)?.items.count == 16)
        #expect(useCase.lastTopLimit == 17)
        await stop(task)
    }

    // MARK: - Pruning bound

    @Test("a short result gives no more tile and the next signal recovers")
    func shortResultRecoversOnNextSignal() async {
        let useCase = MockLeftOffItemsUseCase()
        useCase.topItemsResultsPerCall = [makeResolvedItems(count: 3), makeResolvedItems(count: 9)]
        let signals = makeSignals(for: useCase)
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }
        #expect(loadedParts(sut.state)?.hasMore == false)

        signals.yield(())
        await waitForState(of: sut) { self.loadedParts($0)?.hasMore == true }

        #expect(loadedParts(sut.state)?.items.count == 8)
        await stop(task)
    }

    // MARK: - Live refresh

    @Test("a signal re-queries and updates the items")
    func signalUpdatesItems() async {
        let useCase = MockLeftOffItemsUseCase()
        useCase.topItemsResultsPerCall = [makeResolvedItems(count: 2), makeResolvedItems(count: 3)]
        let signals = makeSignals(for: useCase)
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { self.loadedParts($0)?.items.count == 2 }

        signals.yield(())
        await waitForState(of: sut) { self.loadedParts($0)?.items.count == 3 }

        #expect(useCase.topItemsCallCount == 2)
        await stop(task)
    }

    @Test("an expanded page survives a signal within one run")
    func expandedPageSurvivesSignal() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 30))
        let signals = makeSignals(for: useCase)
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }
        await sut.loadMore()

        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 3 }

        #expect(useCase.lastTopLimit == 17)
        #expect(loadedParts(sut.state)?.items.count == 16)
        await stop(task)
    }

    @Test("a fresh run keeps the expanded page")
    func freshRunKeepsExpandedPage() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 30))
        let sut = makeSUT(useCase: useCase)
        let firstRun = start(sut)
        await waitForState(of: sut) { $0 != .loading }
        await sut.loadMore()
        await stop(firstRun)

        let secondRun = start(sut)
        await waitUntil { useCase.topItemsCallCount == 3 }

        #expect(useCase.lastTopLimit == 17)
        #expect(loadedParts(sut.state)?.items.count == 16)
        await stop(secondRun)
    }

    @Test("an identical result does not reassign the state")
    func identicalResultDoesNotReassignState() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 3))
        let signals = makeSignals(for: useCase)
        let sut = makeSUT(useCase: useCase)
        let counter = ChangeCounter()
        Self.countStateChanges(of: sut, into: counter)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }

        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 2 }
        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 3 }

        #expect(counter.count == 1)
        await stop(task)
    }

    // MARK: - Errors

    @Test("a cancelled fetch leaves the state unchanged")
    func cancelledLeavesStateUnchanged() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 2))
        useCase.topItemsErrorsPerCall = [.cancelled]
        let signals = makeSignals(for: useCase)
        let gate = Gate()
        useCase.onTopItems = { call in
            if call == 2 { await gate.wait() }
        }
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)

        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 2 }

        #expect(sut.state == .loading)
        await stop(task)
    }

    @Test("a persistence failure while loading gives empty")
    func persistenceFailureWhileLoadingGivesEmpty() async {
        let sut = makeSUT(useCase: MockLeftOffItemsUseCase(errorToThrow: .persistenceFailure))
        let task = start(sut)

        await waitForState(of: sut) { $0 == .empty }

        #expect(sut.state == .empty)
        await stop(task)
    }

    @Test("a persistence failure while loaded keeps the items")
    func persistenceFailureWhileLoadedKeepsItems() async {
        let useCase = MockLeftOffItemsUseCase(topItemsResult: makeResolvedItems(count: 3))
        useCase.topItemsErrorsPerCall = [nil, .persistenceFailure]
        let signals = makeSignals(for: useCase)
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 != .loading }

        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 2 }
        signals.yield(())
        await waitUntil { useCase.topItemsCallCount == 3 }

        #expect(loadedParts(sut.state)?.items.count == 3)
        await stop(task)
    }

    // MARK: - Fetch nodes recovery

    @Test("an empty result before the root node exists recovers on the next signal")
    func emptyResultRecoversOnSignal() async {
        let useCase = MockLeftOffItemsUseCase()
        useCase.topItemsResultsPerCall = [[], makeResolvedItems(count: 2)]
        let signals = makeSignals(for: useCase)
        let sut = makeSUT(useCase: useCase)
        let task = start(sut)
        await waitForState(of: sut) { $0 == .empty }

        signals.yield(())
        await waitForState(of: sut) { self.loadedParts($0)?.items.count == 2 }

        #expect(loadedParts(sut.state)?.items.count == 2)
        await stop(task)
    }
}
