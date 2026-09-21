@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import Testing

@MainActor
@Suite("Revamped cancellable transfer view model", .timeLimit(.minutes(1)))
struct RevampedCancellableTransferViewModelTests {

    // MARK: - Starting

    /// Putting the alert on screen is the scheduler's to decide, so the view model only starts its
    /// wait and never reaches for the router itself.
    @Test("On view ready it prepares the widget, schedules the alert and starts the transfers")
    func onViewReady() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = MockCancellableTransferUseCase()
        let alertScheduler = MockCancellableTransferAlertScheduler()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.prepareTransfersWidget_calledTimes == 1)
        #expect(alertScheduler.scheduleForPresent_calledTimes == 1)
        #expect(router.showTransfersAlert_calledTimes == 0)
        #expect(useCase.startedTransfers.count == 1)
    }

    @Test("On view ready while over disk quota it starts nothing")
    func onViewReadyWhenOverDiskQuota() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = MockCancellableTransferUseCase()
        let alertScheduler = MockCancellableTransferAlertScheduler()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: true),
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.prepareTransfersWidget_calledTimes == 0)
        #expect(alertScheduler.scheduleForPresent_calledTimes == 0)
        #expect(router.showTransfersAlert_calledTimes == 0)
        #expect(useCase.startedTransfers.isEmpty)
    }

    @Test("On view ready with nothing to transfer it starts nothing")
    func onViewReadyWithNothingToTransfer() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = MockCancellableTransferUseCase()
        let alertScheduler = MockCancellableTransferAlertScheduler()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            alertScheduler: alertScheduler,
            transfers: [],
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.prepareTransfersWidget_calledTimes == 0)
        #expect(alertScheduler.scheduleForPresent_calledTimes == 0)
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

    /// Dropping the running batch is not the user cancelling it: nothing is reported and the flow
    /// is left standing for the batch that replaced it.
    @Test("On view ready dispatched again it reports nothing for the batch it dropped")
    func onViewReadyDispatchedAgainReportsNothing() async {
        let router = MockRevampedCancellableTransferRouter()
        let alertScheduler = MockCancellableTransferAlertScheduler()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: ManualCancellableTransferUseCase(),
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(router.transferCancelled_calledTimes == 0)
        #expect(router.transferFlowDidFinish_calledTimes == 0)
        #expect(alertScheduler.finish_calledTimes == 0)
        withExtendedLifetime(sut) { }
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
            alertScheduler: MockCancellableTransferAlertScheduler(isPresented: true),
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

    @Test("Tapping cancel ends the alert's presentation")
    func didTapCancelButtonEndsThePresentation() async {
        let router = MockRevampedCancellableTransferRouter()
        let alertScheduler = MockCancellableTransferAlertScheduler()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: [.failed]),
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)
        await waitForRoute(of: sut, on: router)

        #expect(alertScheduler.finish_calledTimes == 1)
    }

    @Test(
        "Tapping cancel asks for a dismiss only when the alert ended up on screen",
        arguments: [true, false]
    )
    func didTapCancelButtonDismissFlag(isPresented: Bool) async {
        let router = MockRevampedCancellableTransferRouter()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: [.failed]),
            alertScheduler: MockCancellableTransferAlertScheduler(isPresented: isPresented),
            transferType: .download)

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)
        await waitForRoute(of: sut, on: router)

        #expect(router.dismissRequests == [isPresented])
    }

    /// Legacy behaviour: an alert that has just gone up is not whipped away the moment Cancel is
    /// tapped, it stays long enough to be read. The scheduler owns that wait, so the view model
    /// has to hold its outcome until the wait is over.
    @Test("Tapping cancel waits out the alert's minimum time on screen before reporting")
    func didTapCancelButtonWaitsOutTheAlert() async {
        let router = MockRevampedCancellableTransferRouter()
        let alertScheduler = MockCancellableTransferAlertScheduler(isPresented: true, holdsFinish: true)
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: ManualCancellableTransferUseCase(),
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        sut.dispatch(.didTapCancelButton)
        await alertScheduler.waitForFinish()

        #expect(router.transferCancelled_calledTimes == 0, "cancelled was reported before the alert had its time on screen")

        alertScheduler.releaseFinish()
        await waitForRoute(of: sut, on: router)

        #expect(router.transferCancelled_calledTimes == 1)
        #expect(router.dismissRequests == [true])
    }

    /// The user tapping Cancel while a terminal state is held behind the alert's minimum time on
    /// screen: the cancel is the newer of the two, so it is what gets reported.
    @Test(
        "Tapping cancel while a terminal state waits for the alert reports the cancel, not the state",
        arguments: [CancellableTransferStateEntity.transferringFiles, .failed]
    )
    func didTapCancelButtonDuringATerminalState(state: CancellableTransferStateEntity) async {
        let router = MockRevampedCancellableTransferRouter()
        let alertScheduler = MockCancellableTransferAlertScheduler(isPresented: true, holdsFinish: true)
        let useCase = ManualCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        useCase.emit(state)
        await alertScheduler.waitForFinish()
        sut.dispatch(.didTapCancelButton)
        alertScheduler.releaseFinish()
        await waitForRoute(of: sut, on: router)

        #expect(router.transferCancelled_calledTimes == 1)
        #expect(router.transferSuccessMessages.isEmpty)
        #expect(router.transferFailed_calledTimes == 0)
    }

    /// The flow gets one last word. A cancel that lands after the batch has already reported its
    /// own outcome is too late to add a second one.
    @Test("Tapping cancel after the batch reported its outcome reports nothing more")
    func didTapCancelButtonAfterTheOutcome() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = ManualCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            alertScheduler: MockCancellableTransferAlertScheduler(isPresented: true),
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        useCase.emit(.transferringFiles)
        await waitForRoute(of: sut, on: router)

        sut.dispatch(.didTapCancelButton)
        await Task.megaYield()

        #expect(router.transferSuccessMessages == [Strings.Localizable.downloadStarted])
        #expect(router.transferCancelled_calledTimes == 0)
        #expect(router.transferFlowDidFinish_calledTimes == 1)
        withExtendedLifetime(sut) { }
    }

    /// Regression: the ordinary cancel lands while the loop is suspended on its next state, so the
    /// loop body never runs again and the iterator simply runs out. Anything that reads the task's
    /// own cancellation from inside that body misses this -- the commonest cancel there is -- and
    /// leaves the alert up with nothing coming to take it away.
    @Test("Tapping cancel while the batch is between states still reports the cancel")
    func didTapCancelButtonBetweenStates() async {
        let router = MockRevampedCancellableTransferRouter()
        let useCase = ManualCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            alertScheduler: MockCancellableTransferAlertScheduler(isPresented: true),
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        useCase.emit(.scanning(name: "folder", folderCount: 1, fileCount: 2))
        await Task.megaYield()
        sut.dispatch(.didTapCancelButton)
        await waitForRoute(of: sut, on: router)

        #expect(router.transferCancelled_calledTimes == 1)
        #expect(router.dismissRequests == [true])
        #expect(router.transferFlowDidFinish_calledTimes == 1)
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

    @Test("A progress state leaves the alert alone")
    func progressStateLeavesTheAlertAlone() async {
        let alertScheduler = MockCancellableTransferAlertScheduler()
        let sut = makeSUT(
            cancellableTransferUseCase: MockCancellableTransferUseCase(
                states: [.scanning(name: "folder", folderCount: 2, fileCount: 3)]),
            alertScheduler: alertScheduler,
            transferType: .download)

        _ = await commands(from: sut, expectedCount: 1)

        #expect(alertScheduler.finish_calledTimes == 0)
        #expect(alertScheduler.scheduleForPresent_calledTimes == 1)
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

    @Test(
        "A terminal state ends the alert's presentation",
        arguments: [CancellableTransferStateEntity.transferringFiles, .failed]
    )
    func terminalStateEndsThePresentation(state: CancellableTransferStateEntity) async {
        let alertScheduler = MockCancellableTransferAlertScheduler()
        _ = await route(states: [state], transferType: .download, alertScheduler: alertScheduler)

        #expect(alertScheduler.finish_calledTimes == 1)
    }

    @Test(
        "A terminal state asks for a dismiss only when the alert ended up on screen",
        arguments: [
            (CancellableTransferStateEntity.transferringFiles, true),
            (.transferringFiles, false),
            (.failed, true),
            // A batch that started inside the delay never put an alert up, so there is nothing
            // to take away and asking would dismiss whatever else happens to be on screen.
            (.failed, false)
        ]
    )
    func terminalStateDismissFlag(state: CancellableTransferStateEntity, isPresented: Bool) async {
        let router = await route(
            states: [state],
            transferType: .download,
            alertScheduler: MockCancellableTransferAlertScheduler(isPresented: isPresented))

        #expect(router.dismissRequests == [isPresented])
    }

    /// The alert's minimum time on screen is what a terminal state waits for, so the outcome is
    /// not reported -- and the alert not taken away -- until the scheduler says it may be.
    @Test("A terminal state waits out the alert's minimum time on screen before reporting")
    func terminalStateWaitsOutTheAlert() async {
        let router = MockRevampedCancellableTransferRouter()
        let alertScheduler = MockCancellableTransferAlertScheduler(isPresented: true, holdsFinish: true)
        let useCase = ManualCancellableTransferUseCase()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: useCase,
            alertScheduler: alertScheduler,
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()
        useCase.emit(.transferringFiles)
        await alertScheduler.waitForFinish()

        #expect(router.transferSuccessMessages.isEmpty, "the outcome was reported before the alert had its time on screen")

        alertScheduler.releaseFinish()
        await waitForRoute(of: sut, on: router)

        #expect(router.transferSuccessMessages == [Strings.Localizable.downloadStarted])
    }

    // MARK: - Helpers

    /// Runs the batch to its terminal state and returns the router it routed through.
    private func route(
        states: [CancellableTransferStateEntity],
        transferType: CancellableTransferType,
        alertScheduler: MockCancellableTransferAlertScheduler = MockCancellableTransferAlertScheduler()
    ) async -> MockRevampedCancellableTransferRouter {
        let router = MockRevampedCancellableTransferRouter()
        let sut = makeSUT(
            router: router,
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: states),
            alertScheduler: alertScheduler,
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

    // MARK: - Recording a downloaded folder offline

    @Test("Reaching the transferring stage records the batch's folders offline")
    func transferringFilesRecordsTheOfflineFolders() async {
        // The batch reports no transfer of its own for a folder, so this is the only place the
        // folder is marked as downloaded.
        let recordUseCase = MockRecordOfflineFolderUseCase()
        let sut = makeSUT(
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: [.transferringFiles]),
            recordOfflineFolderUseCase: recordUseCase,
            transfers: [CancellableTransfer(handle: 1, name: "Docs", isFile: false, type: .download)],
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(recordUseCase.recordedBatches.map { $0.map(\.name) } == [["Docs"]])
    }

    @Test("A batch that failed records nothing offline")
    func failedBatchRecordsNothing() async {
        let recordUseCase = MockRecordOfflineFolderUseCase()
        let sut = makeSUT(
            cancellableTransferUseCase: MockCancellableTransferUseCase(states: [.failed]),
            recordOfflineFolderUseCase: recordUseCase,
            transfers: [CancellableTransfer(handle: 1, name: "Docs", isFile: false, type: .download)],
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(recordUseCase.recordedBatches.isEmpty)
    }

    @Test("A batch still scanning records nothing offline")
    func scanningRecordsNothing() async {
        let recordUseCase = MockRecordOfflineFolderUseCase()
        let sut = makeSUT(
            cancellableTransferUseCase: MockCancellableTransferUseCase(
                states: [.scanning(name: "Docs", folderCount: 1, fileCount: 1)]),
            recordOfflineFolderUseCase: recordUseCase,
            transfers: [CancellableTransfer(handle: 1, name: "Docs", isFile: false, type: .download)],
            transferType: .download)

        sut.dispatch(.onViewReady)
        await Task.megaYield()

        #expect(recordUseCase.recordedBatches.isEmpty)
    }

    // MARK: - Download analytics stats

    @Test("A download of only photos and videos sends the photos and videos event")
    func downloadStatsForMultimediaOnly() {
        let analytics = MockAnalyticsEventUseCase()
        let sut = makeSUT(
            mediaUseCase: MockMediaUseCase(multimediaNodeNames: ["node.mp3"]),
            analyticsEventUseCase: analytics,
            transfers: [CancellableTransfer(handle: 1, name: "node.mp3", type: .download)],
            transferType: .download)

        sut.dispatch(.onViewReady)

        #expect(analytics.type == .download(.makeAvailableOfflinePhotosVideos))
    }

    @Test("A download of no photos and videos sends the make available offline event")
    func downloadStatsForNonMultimediaOnly() {
        let analytics = MockAnalyticsEventUseCase()
        let sut = makeSUT(
            analyticsEventUseCase: analytics,
            transfers: [CancellableTransfer(handle: 1, name: "node.txt", type: .download)],
            transferType: .download)

        sut.dispatch(.onViewReady)

        #expect(analytics.type == .download(.makeAvailableOffline))
    }

    /// The mixed case sends both events. `MockAnalyticsEventUseCase` keeps only the last one,
    /// so this asserts the second event, exactly like the legacy view model's test does.
    @Test("A download of photos, videos and other files sends both events")
    func downloadStatsForMixedSelection() {
        let analytics = MockAnalyticsEventUseCase()
        let sut = makeSUT(
            mediaUseCase: MockMediaUseCase(multimediaNodeNames: ["node.mp3"]),
            analyticsEventUseCase: analytics,
            transfers: [
                CancellableTransfer(handle: 1, name: "node.mp3", type: .download),
                CancellableTransfer(handle: 2, name: "node.txt", type: .download)
            ],
            transferType: .download)

        sut.dispatch(.onViewReady)

        #expect(analytics.type == .download(.makeAvailableOffline))
    }

    @Test("A chat download sends the stats event")
    func downloadStatsForChat() {
        let analytics = MockAnalyticsEventUseCase()
        let sut = makeSUT(analyticsEventUseCase: analytics, transferType: .downloadChat)

        sut.dispatch(.onViewReady)

        #expect(analytics.type == .download(.makeAvailableOffline))
    }

    @Test(
        "An upload or a file link download sends no stats event",
        arguments: [CancellableTransferType.upload, .downloadFileLink]
    )
    func noDownloadStatsForOtherTransferTypes(transferType: CancellableTransferType) {
        let analytics = MockAnalyticsEventUseCase()
        let sut = makeSUT(analyticsEventUseCase: analytics, transferType: transferType)

        sut.dispatch(.onViewReady)

        #expect(analytics.type == nil)
    }

    private func makeSUT(
        router: MockRevampedCancellableTransferRouter = MockRevampedCancellableTransferRouter(),
        cancellableTransferUseCase: some CancellableTransferUseCaseProtocol = MockCancellableTransferUseCase(),
        recordOfflineFolderUseCase: MockRecordOfflineFolderUseCase = MockRecordOfflineFolderUseCase(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        alertScheduler: MockCancellableTransferAlertScheduler = MockCancellableTransferAlertScheduler(),
        mediaUseCase: MockMediaUseCase = MockMediaUseCase(),
        analyticsEventUseCase: MockAnalyticsEventUseCase = MockAnalyticsEventUseCase(),
        transfers: [CancellableTransfer] = [CancellableTransfer(handle: 1, name: "node.txt", type: .download)],
        transferType: CancellableTransferType
    ) -> RevampedCancellableTransferViewModel {
        RevampedCancellableTransferViewModel(
            router: router,
            cancellableTransferUseCase: cancellableTransferUseCase,
            recordOfflineFolderUseCase: recordOfflineFolderUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker,
            alertScheduler: alertScheduler,
            mediaUseCase: mediaUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
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

    func transferSuccess(with message: String, dismiss: Bool) {
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

final class MockCancellableTransferAlertScheduler: CancellableTransferAlertScheduling {
    /// Whether `finish()` reports that the alert ended up on screen.
    private let isPresented: Bool
    /// Whether `finish()` suspends until `releaseFinish()`, standing in for the alert waiting out
    /// its minimum time on screen.
    private var holdsFinish: Bool
    private var held = [CheckedContinuation<Void, Never>]()

    private(set) var scheduleForPresent_calledTimes = 0
    private(set) var finish_calledTimes = 0

    nonisolated init(isPresented: Bool = false, holdsFinish: Bool = false) {
        self.isPresented = isPresented
        self.holdsFinish = holdsFinish
    }

    func scheduleForPresent() {
        scheduleForPresent_calledTimes += 1
    }

    func finish() async -> Bool {
        finish_calledTimes += 1
        if holdsFinish {
            await withCheckedContinuation { held.append($0) }
        }
        return isPresented
    }

    /// Suspends until a `finish()` is being held, so a test can act while the caller waits.
    func waitForFinish(maximumYields: Int = 1000) async {
        var yields = 0
        while held.isEmpty, yields < maximumYields {
            yields += 1
            await Task.yield()
        }
    }

    /// Lets every held `finish()` return, and stops holding the ones that follow.
    func releaseFinish() {
        holdsFinish = false
        let waiting = held
        held = []
        waiting.forEach { $0.resume() }
    }
}

/// A batch whose states a test emits one at a time, and which never ends on its own, so a test can
/// act between two of them.
final class ManualCancellableTransferUseCase: CancellableTransferUseCaseProtocol, @unchecked Sendable {
    @Atomic private var continuations = [AsyncStream<CancellableTransferStateEntity>.Continuation]()
    @Atomic var cancel_calledTimes = 0

    func start(transfers: [CancellableTransferEntity]) -> AnyAsyncSequence<CancellableTransferStateEntity> {
        let (stream, continuation) = AsyncStream.makeStream(of: CancellableTransferStateEntity.self)
        $continuations.mutate { $0.append(continuation) }
        return stream.eraseToAnyAsyncSequence()
    }

    /// Reports a state to every batch started so far.
    func emit(_ state: CancellableTransferStateEntity) {
        continuations.forEach { $0.yield(state) }
    }

    func cancel() {
        $cancel_calledTimes.mutate { $0 += 1 }
    }
}
