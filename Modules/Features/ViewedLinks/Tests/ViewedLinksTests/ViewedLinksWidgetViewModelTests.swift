import Foundation
import MEGADomain
import MEGASwift
import Testing
@testable import ViewedLinks
import ViewedLinksMock

@Suite("ViewedLinksWidgetViewModel", .timeLimit(.minutes(1)))
@MainActor
struct ViewedLinksWidgetViewModelTests {
    // MARK: - Initial load

    @Test("state is loading before onTask runs")
    func initialStateIsLoading() {
        let sut = makeSUT(useCase: MockViewedLinksUseCase())

        #expect(isLoading(sut.state))
    }

    @Test("onTask forwards the configured limit to the use case")
    func onTaskForwardsLimit() async throws {
        let useCase = MockViewedLinksUseCase(topViewedLinksResult: try links(handles: 1...6))
        let sut = makeSUT(useCase: useCase, limit: 2)

        await sut.onTask()

        #expect(useCase.lastTopLimit == 2)
        let ids = try rowIDs(sut.state)
        #expect(ids == [1, 2])
    }

    @Test("rows keep the order the use case returned")
    func onTaskKeepsUseCaseOrder() async throws {
        let useCase = MockViewedLinksUseCase(topViewedLinksResult: try links(handles: [3, 1, 2]))
        let sut = makeSUT(useCase: useCase)

        await sut.onTask()

        let ids = try rowIDs(sut.state)
        #expect(ids == [3, 1, 2])
    }

    @Test("onTask with no stored links ends in the empty state")
    func onTaskWithNoLinksIsEmpty() async {
        let sut = makeSUT(useCase: MockViewedLinksUseCase(topViewedLinksResult: []))

        await sut.onTask()

        #expect(isEmpty(sut.state))
    }

    // MARK: - Failures

    @Test(
        "a fetch failure on the first load ends in the empty state",
        arguments: [ViewedLinkErrorEntity.notFound, .storeOperationFailed]
    )
    func fetchFailureWhileLoadingIsEmpty(error: ViewedLinkErrorEntity) async {
        let useCase = MockViewedLinksUseCase(errorToThrow: error)
        let sut = makeSUT(useCase: useCase)

        await sut.onTask()

        #expect(isEmpty(sut.state))
    }

    @Test("a cancelled fetch on the first load leaves the state untouched")
    func cancelledFetchWhileLoadingStaysLoading() async {
        let useCase = MockViewedLinksUseCase(errorToThrow: .cancelled)
        let sut = makeSUT(useCase: useCase)

        await sut.onTask()

        #expect(isLoading(sut.state))
    }

    @Test("a failure after a successful load moves to the empty state")
    func failureAfterLoadIsEmpty() async throws {
        let useCase = MockViewedLinksUseCase(topViewedLinksResult: try links(handles: [1, 2]))
        let (signals, continuation) = AsyncStream<Void>.makeStream()
        useCase.changesSignalSequenceResult = signals.eraseToAnyAsyncSequence()
        let sut = makeSUT(useCase: useCase)

        let task = Task { await sut.onTask() }
        await waitForLoadedRows(on: sut)

        useCase.errorToThrow = .storeOperationFailed
        continuation.yield(())
        continuation.finish()
        await task.value

        #expect(isEmpty(sut.state))
    }

    // MARK: - Live refresh

    @Test("a change signal refetches and republishes the new order")
    func changeSignalRefetches() async throws {
        let useCase = MockViewedLinksUseCase(topViewedLinksResult: try links(handles: [1, 2]))
        let (signals, continuation) = AsyncStream<Void>.makeStream()
        useCase.changesSignalSequenceResult = signals.eraseToAnyAsyncSequence()
        let sut = makeSUT(useCase: useCase)

        let task = Task { await sut.onTask() }
        await waitForLoadedRows(on: sut)

        useCase.topViewedLinksResult = try links(handles: [2, 1])
        continuation.yield(())
        continuation.finish()
        await task.value

        let ids = try rowIDs(sut.state)
        #expect(ids == [2, 1])
    }

    @Test("a renamed link is republished for the same handle")
    func renameRepublishesLink() async throws {
        let useCase = MockViewedLinksUseCase(topViewedLinksResult: try links(handles: [1]))
        let (signals, continuation) = AsyncStream<Void>.makeStream()
        useCase.changesSignalSequenceResult = signals.eraseToAnyAsyncSequence()
        let sut = makeSUT(useCase: useCase)

        let task = Task { await sut.onTask() }
        await waitForLoadedRows(on: sut)

        useCase.topViewedLinksResult = [try makeLink(handle: 1, name: "renamed.jpg")]
        continuation.yield(())
        continuation.finish()
        await task.value

        let names = try rows(sut.state).map(\.name)
        #expect(names == ["renamed.jpg"])
    }

    @Test("a change signal that returns no links moves to the empty state")
    func changeSignalToEmpty() async throws {
        let useCase = MockViewedLinksUseCase(topViewedLinksResult: try links(handles: [1, 2]))
        let (signals, continuation) = AsyncStream<Void>.makeStream()
        useCase.changesSignalSequenceResult = signals.eraseToAnyAsyncSequence()
        let sut = makeSUT(useCase: useCase)

        let task = Task { await sut.onTask() }
        await waitForLoadedRows(on: sut)

        useCase.topViewedLinksResult = []
        continuation.yield(())
        continuation.finish()
        await task.value

        #expect(isEmpty(sut.state))
    }

    // MARK: - Helpers

    private func makeSUT(useCase: MockViewedLinksUseCase, limit: Int = 4) -> ViewedLinksWidgetViewModel {
        ViewedLinksWidgetViewModel(
            viewedLinksUseCase: useCase,
            limit: limit
        )
    }

    /// The signal stream never finishes on its own, so the test drives it. This waits for the first
    /// load rather than sleeping, which would make these flaky.
    private func waitForLoadedRows(on sut: ViewedLinksWidgetViewModel) async {
        if case .loaded = sut.state { return }
        for await state in sut.$state.values {
            if case .loaded = state { return }
        }
    }

    private func isLoading(_ state: ViewedLinksWidgetViewModel.State) -> Bool {
        if case .loading = state { return true }
        return false
    }

    private func isEmpty(_ state: ViewedLinksWidgetViewModel.State) -> Bool {
        if case .empty = state { return true }
        return false
    }

    private func rows(_ state: ViewedLinksWidgetViewModel.State) throws -> [ViewedLinkEntity] {
        guard case .loaded(let rows) = state else {
            throw TestFailure.notLoaded
        }
        return rows.map(\.link)
    }

    private func rowIDs(_ state: ViewedLinksWidgetViewModel.State) throws -> [HandleEntity] {
        try rows(state).map(\.handle)
    }

    private func links(handles: some Sequence<Int>) throws -> [ViewedLinkEntity] {
        try handles.map { try makeLink(handle: HandleEntity($0)) }
    }

    private func makeLink(
        handle: HandleEntity,
        name: String? = nil,
        isFolder: Bool = false
    ) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(
            handle: handle,
            linkURL: url,
            name: name ?? "file\(handle).jpg",
            isFolder: isFolder,
            lastAccessed: Date(timeIntervalSince1970: TimeInterval(handle))
        )
    }

    private enum TestFailure: Error {
        case notLoaded
    }
}
