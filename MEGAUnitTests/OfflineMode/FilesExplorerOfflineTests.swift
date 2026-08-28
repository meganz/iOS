@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGAUIComponent
import Testing

/// The Audio (and Documents) chip list adopting the new offline mode: a file with no local copy
/// warns instead of opening nothing, and the actions that need a connection prompt (IOS-12411).
@MainActor
@Suite("Files explorer offline mode")
struct FilesExplorerOfflineTests {

    /// The guard resolves the node asynchronously, so the tap only warns a turn later.
    @Test("Tapping a file with no local copy while offline shows the file unavailable snack bar",
          .timeLimit(.minutes(1)))
    func fileWithNoLocalCopyShowsSnackBar() async throws {
        let node = MockNode(handle: 1, name: "song.mp3")
        let (sut, tapDispatcher) = makeSUT(
            offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: true, shouldBlock: true),
            nodeUseCase: MockNodeUseCase(nodes: [1: NodeEntity(handle: 1)])
        )
        var snackBarShown = false
        tapDispatcher.showFileUnavailableSnackBar = { snackBarShown = true }

        sut.dispatch(.didSelectNode(node, [node]))

        try await wait { snackBarShown }
    }

    // The pass-through — a file that does open — is covered by `OfflineAwareNodeTapDispatcherTests`;
    // exercising it here would launch the real player.

    /// The empty-list regression (IOS-12411): the explorer asks for its first search from its own
    /// `viewDidLoad`, before its view has a superview, and the container's state machine has to
    /// find it at that exact moment. Asserting on `childViewController` after the fact does not
    /// cover it — by then the view is attached and any lookup works — so this asserts the symptom
    /// a user would see instead: whether a search was ever requested.
    @Test("Showing the explorer requests a first search even with the offline banner installed",
          .timeLimit(.minutes(1)))
    func showingTheExplorerRequestsASearch() async throws {
        let searchUseCase = MockFilesSearchUseCase()
        let container = FilesExplorerContainerViewController(
            viewModel: makeSUT(searchUseCase: searchUseCase).0,
            viewPreference: .both,
            isNewOfflineModeEnabled: true
        )

        container.loadViewIfNeeded()

        // The search is dispatched onto a task, so it lands a turn or more later.
        try await wait { searchUseCase.messages.contains(.search) }
    }

    @Test("Downloading a node consults the offline action guard")
    func downloadNodeConsultsTheGuard() {
        let offlineActionGuard = MockOfflineActionGuard(allowsAction: false)
        let (sut, _) = makeSUT(offlineActionGuard: offlineActionGuard)

        sut.dispatch(.downloadNode(MockNode(handle: 1)))

        #expect(offlineActionGuard.allowsActionRequiringConnectionCallCount == 1)
    }

    @Test("The upload/add menu forwards an action only when the guard allows it", arguments: [true, false])
    func uploadAddMenuFollowsTheGuard(allowsAction: Bool) {
        let (sut, _) = makeSUT(offlineActionGuard: MockOfflineActionGuard(allowsAction: allowsAction))
        var selectedActions: [UploadAddActionEntity] = []
        sut.invokeCommand = { if case .didSelect(let action) = $0 { selectedActions.append(action) } }

        sut.uploadAddMenu(didSelect: .newFolder)

        #expect(selectedActions == (allowsAction ? [.newFolder] : []))
    }

    // MARK: - Helpers

    /// Suspends until `condition` holds.
    ///
    /// `Task.sleep` is what makes the enclosing `.timeLimit` able to end this: it throws when the
    /// task is cancelled. `Task.yield()` keeps spinning through cancellation, and a
    /// `withCheckedContinuation` that is never resumed can never be cancelled at all — either one
    /// turns "the callback never came" into a hung test rather than a failing one.
    private func wait(until condition: () -> Bool) async throws {
        while !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func makeSUT(
        explorerType: ExplorerTypeEntity = .audio,
        searchUseCase: MockFilesSearchUseCase = MockFilesSearchUseCase(),
        offlineActionGuard: MockOfflineActionGuard = MockOfflineActionGuard(),
        offlineFileOpenGuard: MockOfflineFileOpenGuard = MockOfflineFileOpenGuard(isActive: false),
        nodeUseCase: MockNodeUseCase = MockNodeUseCase()
    ) -> (FilesExplorerViewModel, OfflineAwareNodeTapDispatcher) {
        let tapDispatcher = OfflineAwareNodeTapDispatcher(
            offlineFileOpenGuard: offlineFileOpenGuard,
            nodeUseCase: nodeUseCase
        )
        let sut = FilesExplorerViewModel(
            explorerType: explorerType,
            router: FilesExplorerRouter(navigationController: nil, explorerType: explorerType),
            useCase: searchUseCase,
            nodeDownloadUpdatesUseCase: MockNodeDownloadUpdatesUseCase(),
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(),
            createContextMenuUseCase: MockCreateContextMenuUseCase(),
            nodeProvider: MockMEGANodeProvider(nodes: []),
            sortHeaderConfig: SortHeaderConfig(title: "", options: []),
            offlineActionGuard: offlineActionGuard,
            offlineNodeTapDispatcher: tapDispatcher,
            tracker: MockTracker()
        )
        return (sut, tapDispatcher)
    }
}

private struct MockNodeDownloadUpdatesUseCase: NodeDownloadUpdatesUseCaseProtocol {
    func startMonitoringDownloadCompletion(for nodes: [NodeEntity]) -> AnyAsyncSequence<NodeEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }

    func startMonitoringDownloadProgress(for node: NodeEntity) -> AnyAsyncSequence<DownloadProgress> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
