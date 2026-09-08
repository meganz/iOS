@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@MainActor
@Suite("Revamped cancellable transfer view model", .timeLimit(.minutes(1)))
struct RevampedCancellableTransferViewModelTests {

    // MARK: - Starting

    @Test("On view ready it prepares the widget, shows the alert and starts the transfers")
    func onViewReady() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = MockCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.prepareTransfersWidget_calledTimes == 1)
        #expect(router.showTransfersAlert_calledTimes == 1)
        #expect(useCase.startedTransfers.count == 1)
    }

    @Test("On view ready while over disk quota it starts nothing")
    func onViewReadyWhenOverDiskQuota() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = MockCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: true),
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.prepareTransfersWidget_calledTimes == 0)
        #expect(router.showTransfersAlert_calledTimes == 0)
        #expect(useCase.startedTransfers.isEmpty)
    }

    @Test("On view ready with nothing to transfer it starts nothing")
    func onViewReadyWithNothingToTransfer() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = MockCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            transfers: [],
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.prepareTransfersWidget_calledTimes == 0)
        #expect(router.showTransfersAlert_calledTimes == 0)
        #expect(useCase.startedTransfers.isEmpty)
    }

    @Test("On view ready it hands every transfer over as the entity the use case takes")
    func onViewReadyHandsTransfersOver() async throws {
        let useCase = MockCancellableTransferUseCase()
        let sut = makeSUT(
            cancellableTransferUseCase: useCase,
            transfers: [
                CancellableTransfer(handle: 3, messageId: 4, chatId: 5, name: "node.txt", type: .downloadChat),
                CancellableTransfer(handle: 6, name: "other.txt", type: .downloadChat)
            ],
            transferType: .downloadChat)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        let started = try #require(useCase.startedTransfers.first)
        #expect(started.map(\.handle) == [3, 6])
        #expect(started.first?.messageId == 4)
        #expect(started.first?.chatId == 5)
        #expect(started.first?.name == "node.txt")
    }

    /// Dispatched again -- a view that reappeared -- the running batch is dropped rather than
    /// left to route a second terminal state at the screen.
    @Test("On view ready dispatched again it drops the running batch and starts afresh")
    func onViewReadyDispatchedAgain() async {
        let useCase = MockCancellableTransferUseCase()
        let sut = makeSUT(cancellableTransferUseCase: useCase, transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(useCase.startedTransfers.count == 2)
    }

    // MARK: - Cancelling

    @Test("Tapping cancel shows cancelling and cancels the batch")
    func didTapCancelButton() {
        let useCase = MockCancellableTransferUseCase()
        let sut = makeSUT(cancellableTransferUseCase: useCase, transferType: .download)
        var commands = [Command]()
        sut.invokeCommand = { commands.append($0) }

        sut.dispatch(.didTapCancelButton)

        #expect(commands == [.cancelling])
        #expect(useCase.cancel_calledTimes == 1)
    }

    /// A cancelled batch surfaces as a failure from the data layer, but the user asked for it:
    /// what they get told is that the transfers were cancelled, not that they went wrong.
    @Test("Tapping cancel routes cancelled rather than whatever the batch ends as")
    func didTapCancelButtonRoutesCancelled() async {
        let router = MockRevampedCancellableTransferRouter()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: [.failed]),
            transferType: .download)

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)
        await waitForRoute(of: sut, on: router)

        #expect(router.transferCancelled_calledTimes == 1)
        #expect(router.transferFailed_calledTimes == 0)
        #expect(router.transferFlowDidFinish_calledTimes == 1)
    }

    @Test("Tapping cancel routes cancelled once however many states follow")
    func didTapCancelButtonRoutesCancelledOnce() async {
        let router = MockRevampedCancellableTransferRouter()
        let states: [CancellableTransferStateEntity] = [
            .scanning(name: "folder", folderCount: 1, fileCount: 2),
            .creatingFolders(created: 1, total: 1),
            .transferringFiles
        ]
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: states),
            transferType: .download)

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)
        await waitForRoute(of: sut, on: router)

        #expect(router.transferCancelled_calledTimes == 1)
        #expect(router.transferSuccessMessages.isEmpty)
    }

    // MARK: - Progress states

    @Test(
        "A progress state invokes the command that displays it",
        arguments: [
            (
                CancellableTransferStateEntity.scanning(name: "folder", folderCount: 2, fileCount: 3),
                Command.scanning(name: "folder", folders: 2, files: 3)
            ),
            (
                .creatingFolders(created: 1, total: 4),
                .creatingFolders(createdFolders: 1, totalFolders: 4)
            )
        ]
    )
    func progressState(state: CancellableTransferStateEntity, expectedCommand: Command) async {
        let sut = makeSUT(
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: [state]),
            transferType: .download)

        let invokedCommands = await commands(from: sut, expectedCount: 1)

        #expect(invokedCommands == [expectedCommand])
    }

    // MARK: - Terminal states

    @Test(
        "A batch that reached its transferring stage routes the started message of its transfer type",
        arguments: [
            (CancellableTransferType.download, Strings.Localizable.downloadStarted),
            (.downloadChat, Strings.Localizable.downloadStarted),
            (.downloadFileLink, Strings.Localizable.downloadStarted),
            (.upload, Strings.Localizable.uploadStartedMessage)
        ]
    )
    func transferringFilesState(transferType: CancellableTransferType, expectedMessage: String) async {
        let router = await route(states: [.transferringFiles], transferType: transferType)

        #expect(router.transferSuccessMessages == [expectedMessage])
    }

    @Test("A failed batch routes failed")
    func failedState() async {
        let router = await route(states: [.failed], transferType: .download)

        #expect(router.transferFailed_calledTimes == 1)
    }

    /// The flow is self-retained through router -> wrapper -> view model -> router, so a terminal
    /// state has to tell the router to tear it down or the whole flow leaks.
    @Test(
        "A terminal state finishes the flow",
        arguments: [CancellableTransferStateEntity.transferringFiles, .failed]
    )
    func terminalStateFinishesTheFlow(state: CancellableTransferStateEntity) async {
        let router = await route(states: [state], transferType: .download)

        #expect(router.transferFlowDidFinish_calledTimes == 1)
    }

    @Test("On view ready while over disk quota it finishes the flow")
    func onViewReadyWhenOverDiskQuotaFinishesTheFlow() {
        let router = MockRevampedCancellableTransferRouter()
        let sut = makeSUT(
            router: router,
            overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: true),
            transferType: .download)

        sut.dispatch(.onViewReady)

        #expect(router.transferFlowDidFinish_calledTimes == 1)
    }

    @Test("On view ready with nothing to transfer it finishes the flow")
    func onViewReadyWithNothingToTransferFinishesTheFlow() {
        let router = MockRevampedCancellableTransferRouter()
        let sut = makeSUT(router: router, transfers: [], transferType: .download)

        sut.dispatch(.onViewReady)

        #expect(router.transferFlowDidFinish_calledTimes == 1)
    }

    /// The alert goes up as the batch starts, so by the time a terminal state is routed there is
    /// always one on screen to take away.
    @Test("A terminal state asks for the alert to be dismissed")
    func terminalStateDismissesTheAlert() async {
        let router = await route(states: [.transferringFiles], transferType: .download)

        #expect(router.dismissRequests == [true])
    }

    // MARK: - Helpers

    /// Runs the batch to its terminal state and returns the router it routed through.
    private func route(
        states: [CancellableTransferStateEntity],
        transferType: CancellableTransferType
    ) async -> MockRevampedCancellableTransferRouter {
        let router = MockRevampedCancellableTransferRouter()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: states),
            transferType: transferType)

        sut.dispatch(.onViewReady)
        await waitForRoute(of: sut, on: router)

        return router
    }

    /// Suspends until the batch routes a terminal state.
    ///
    /// The task reading the states holds the view model weakly, so the view model has to be kept
    /// alive for as long as the wait lasts or the states it should route go nowhere.
    private func waitForRoute(
        of sut: RevampedCancellableTransferViewModel,
        on router: MockRevampedCancellableTransferRouter
    ) async {
        await router.waitForRoute()
        withExtendedLifetime(sut) { }
    }

    /// Collects the commands the view model invokes while the batch runs.
    private func commands(
        from sut: RevampedCancellableTransferViewModel,
        expectedCount: Int
    ) async -> [Command] {
        let (stream, continuation) = AsyncStream.makeStream(of: Command.self)
        sut.invokeCommand = { continuation.yield($0) }

        sut.dispatch(.onViewReady)

        var invokedCommands = [Command]()
        for await command in stream {
            invokedCommands.append(command)
            if invokedCommands.count == expectedCount {
                break
            }
        }
        continuation.finish()

        return invokedCommands
    }

    private func makeSUT(
        router: MockRevampedCancellableTransferRouter = MockRevampedCancellableTransferRouter(),
        cancellableTransferUseCase: some CancellableTransferUseCaseProtocol = MockCancellableTransferUseCase(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        transfers: [CancellableTransfer] = [CancellableTransfer(handle: 1, name: "node.txt", type: .download)],
        transferType: CancellableTransferType
    ) -> RevampedCancellableTransferViewModel {
        RevampedCancellableTransferViewModel(
            router: router,
            cancellableTransferUseCase: cancellableTransferUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker,
            transfers: transfers,
            transferType: transferType)
    }
}

final class MockRevampedCancellableTransferRouter: CancellableTransferRouting, CancellableTransferFlowLifecycleRouting, TransferWidgetRouting {
    var prepareTransfersWidget_calledTimes = 0
    var transferFlowDidFinish_calledTimes = 0
    var showTransfersAlert_calledTimes = 0
    var transferCancelled_calledTimes = 0
    var transferFailed_calledTimes = 0
    var transferCompletedWithError_calledTimes = 0

    var transferSuccessMessages = [String]()
    /// The `dismiss` flag of every terminal routing call, in call order.
    var dismissRequests = [Bool]()

    /// Yields once per terminal routing call. Buffered, so `waitForRoute()` still returns for a
    /// batch that ended before the test got round to awaiting it.
    private let routes: AsyncStream<Void>
    private let routesContinuation: AsyncStream<Void>.Continuation

    nonisolated init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        routes = stream
        routesContinuation = continuation
    }

    /// Suspends until a terminal state has been routed. Await it once per router.
    func waitForRoute() async {
        for await _ in routes {
            break
        }
    }

    func prepareTransfersWidget() {
        prepareTransfersWidget_calledTimes += 1
    }

    func transferFlowDidFinish() {
        transferFlowDidFinish_calledTimes += 1
    }

    func showTransfersAlert() {
        showTransfersAlert_calledTimes += 1
    }

    func transferSuccess(with message: String, dismiss: Bool, downloadOutcome _: CancellableDownloadOutcome?) {
        transferSuccessMessages.append(message)
        didRoute(dismiss: dismiss)
    }

    func transferCancelled(with message: String, dismiss: Bool) {
        transferCancelled_calledTimes += 1
        didRoute(dismiss: dismiss)
    }

    func transferFailed(error: String, dismiss: Bool) {
        transferFailed_calledTimes += 1
        didRoute(dismiss: dismiss)
    }

    func transferCompletedWithError(error: String, dismiss: Bool) {
        transferCompletedWithError_calledTimes += 1
        didRoute(dismiss: dismiss)
    }

    private func didRoute(dismiss: Bool) {
        dismissRequests.append(dismiss)
        routesContinuation.yield()
    }
}
