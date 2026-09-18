import FolderLink
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import Testing

@Suite("FolderLinkViewModel Tests")
@MainActor
struct FolderLinkViewModelTests {
    @Test("start success sets results state")
    func start_success_setsResults() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .success(NodeEntity(handle: 123)))
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.startLoadingFolderLink()
        
        #expect(sut.viewState == .results(123))
    }

    @Test("start login requires decryption key sets askingForDecryptionKey")
    func start_loginRequiresKey_setsAsking() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .failure(.missingDecryptionKey))
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.startLoadingFolderLink()
        
        #expect(sut.viewState == .loading)
        #expect(sut.askingForDecryptionKey == true)
    }

    @Test("start generic error sets error state")
    func start_generic_setsError() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(.generic)))
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.startLoadingFolderLink()
        
        #expect(sut.viewState == .error(.generic))
    }

    @Test("confirmDecryptionKey success sets results state")
    func confirmKey_success_setsResults() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .success(NodeEntity(handle: 123)))
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.confirmDecryptionKey("key")
        #expect(sut.viewState == .results(123))
        #expect(sut.notifyInvalidDecryptionKey == false)
    }

    @Test("confirmDecryptionKey invalid key sets notifyInvalidDecryptionKey")
    func confirmKey_invalid_setsNotify() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .failure(.invalidDecryptionKey))
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.confirmDecryptionKey("bad-key")
        
        #expect(sut.viewState == .loading)
        #expect(sut.notifyInvalidDecryptionKey == true)
    }

    @Test("confirmDecryptionKey generic error sets error state")
    func confirmKey_generic_setsError() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .failure(.linkUnavailable(.generic)))
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.confirmDecryptionKey("some-key")
        
        #expect(sut.viewState == .error(.generic))
    }

    @Test("cancelConfirmingDecryptionKey calls stop on flow use case")
    func cancel_callsStop() {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase()
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        sut.cancelConfirmingDecryptionKey()
        
        #expect(folderLinkFlowUseCase.stopCalled == true)
    }

    @Test("acknowledgeInvalidDecryptionKey sets askingForDecryptionKey true")
    func acknowledgeInvalid_setsAskingTrue() {
        let sut = FolderLinkViewModelTests.makeSUT()
        
        sut.acknowledgeInvalidDecryptionKey()
        
        #expect(sut.askingForDecryptionKey == true)
    }
    
    @Test("retryPendinConnections should call retry on repository")
    func retryPendinConnections() {
        // Given
        let pendingConnectionRetryUseCase = MockFolderLinkPendingConnectionsRetryUseCase()
        let sut = FolderLinkViewModelTests.makeSUT(pendingConnectionsRetryUseCase: pendingConnectionRetryUseCase)
        
        // When
        sut.retryPendingConnections()
        
        // Then
        #expect(pendingConnectionRetryUseCase.retryPendingConnectionsCalled == true)
    }
    
    @Test(
        "stopLoadingFolderLink should call stop on use case",
        arguments: [
            (true, true),
            (false, false)
        ]
    )
    func stopLoadingFolderLink(shouldLogout: Bool, expectedCalledStopShouldLogout: Bool) {
        // Given
        let folderLinkLogoutPolicy = MockFolderLinkLogoutPolicy(shouldLogout: shouldLogout)
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase()
        let sut = FolderLinkViewModelTests.makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase, folderLinkLogoutPolicy: folderLinkLogoutPolicy)
        
        // When
        sut.stopLoadingFolderLink()
        
        // Then
        #expect(folderLinkFlowUseCase.stopCalled == true)
        let (calledShouldLogout) = folderLinkFlowUseCase.stopCalledArguments
        #expect(calledShouldLogout == expectedCalledStopShouldLogout)
    }
    
    @MainActor
    @Suite("NoNetworkConnectionState Tests")
    struct NoNetworkConnectionState {
        @Test(
            "should get current network state",
            arguments: [true, false]
        )
        func onAppear_shouldGetCurrentState(connected: Bool) async throws {
            let networkUseCase = MockNetworkMonitorUseCase(connected: connected)
            let sut = makeSUT(networkUseCase: networkUseCase)
            #expect(sut.isNetworkConnected == connected)
        }
        
        @Test
        func onAppear_shouldMonitorAndUpdate() async throws {
            let updates = [true, false, true, true, false]
            let networkUseCase = MockNetworkMonitorUseCase(
                connected: true,
                connectionSequence: updates.async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(networkUseCase: networkUseCase)
            #expect(sut.isNetworkConnected == true)
            await sut.onAppear()
            #expect(sut.isNetworkConnected == false)
        }
    }

    // MARK: - Analytics

    @Test("the screen reports itself as soon as it is up, before the link has resolved")
    func trackScreenView_reportsScreenViewEvent() {
        let tracker = MockTracker()
        let sut = FolderLinkViewModelTests.makeSUT(tracker: tracker)

        sut.trackScreenView()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [FolderLinkScreenEvent()]
        )
    }

    /// This view serves both arms of the rollout, unlike the file link whose pre-revamp screen is a
    /// different view controller. Without the gate the control arm would report the revamp's exposure.
    @Test("the pre-revamp screen reports no screen view event")
    func trackScreenView_whenLinkRevampDisabled_reportsNothing() {
        let tracker = MockTracker()
        let sut = FolderLinkViewModelTests.makeSUT(tracker: tracker, isLinkRevampEnabled: false)

        sut.trackScreenView()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    /// The opened event is the numerator of the funnel the screen view event gives a denominator to, so a
    /// link that never opens must not report it.
    @Test("an unavailable link is not reported as opened")
    func start_failure_doesNotReportFolderLinkOpened() async {
        let tracker = MockTracker()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(.expired))),
            tracker: tracker
        )

        await sut.startLoadingFolderLink()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    // MARK: - Viewed link reporting

    @Test("a resolved link is reported with its root node and the received link")
    func start_success_reportsResolvedLink() async {
        let rootNode = NodeEntity(name: "Shared folder", handle: 123)
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(initialStartResult: .success(rootNode)),
            linkResolutionReporter: reporter,
            receivedLink: "https://mega.nz/folder/abc"
        )

        await sut.startLoadingFolderLink()

        #expect(reporter.resolvedCalls.count == 1)
        #expect(reporter.resolvedCalls.first?.folderNode == rootNode)
        #expect(reporter.resolvedCalls.first?.receivedLink == "https://mega.nz/folder/abc")
        #expect(reporter.unavailableCalls.isEmpty)
    }

    /// A password-protected link is opened in its decrypted form, so the reported link must be the one
    /// the caller passed in rather than the one the flow logged in with.
    @Test("a link received in encrypted form is reported in that form")
    func start_success_reportsReceivedLinkNotResolvedLink() async {
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(initialStartResult: .success(NodeEntity(name: "Folder", handle: 1))),
            linkResolutionReporter: reporter,
            receivedLink: "https://mega.nz/#P!encrypted"
        )

        await sut.startLoadingFolderLink()

        #expect(reporter.resolvedCalls.first?.receivedLink == "https://mega.nz/#P!encrypted")
    }

    @Test("a link resolved after a typed decryption key is reported")
    func confirmKey_success_reportsResolvedLink() async {
        let rootNode = NodeEntity(name: "Keyed folder", handle: 456)
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .success(rootNode)),
            linkResolutionReporter: reporter
        )

        await sut.confirmDecryptionKey("key")

        #expect(reporter.resolvedCalls.first?.folderNode == rootNode)
    }

    @Test(
        "a link that is gone is reported as unavailable",
        arguments: [LinkUnavailableReason.downETD, .userETDSuspension, .copyrightSuspension, .expired, .removed]
    )
    func start_terminalFailure_reportsUnavailable(reason: LinkUnavailableReason) async {
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(reason))),
            linkResolutionReporter: reporter,
            receivedLink: "https://mega.nz/folder/gone"
        )

        await sut.startLoadingFolderLink()

        #expect(reporter.unavailableCalls == ["https://mega.nz/folder/gone"])
        #expect(reporter.resolvedCalls.isEmpty)
    }

    /// A generic failure can be transient, so the stored link has to survive it.
    @Test("a generic failure is not reported as unavailable")
    func start_genericFailure_reportsNothing() async {
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(.generic))),
            linkResolutionReporter: reporter
        )

        await sut.startLoadingFolderLink()

        #expect(sut.viewState == .error(.generic))
        #expect(reporter.unavailableCalls.isEmpty)
    }

    @Test("a link waiting on its decryption key is reported neither way")
    func start_missingKey_reportsNothing() async {
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(initialStartResult: .failure(.missingDecryptionKey)),
            linkResolutionReporter: reporter
        )

        await sut.startLoadingFolderLink()

        #expect(reporter.resolvedCalls.isEmpty)
        #expect(reporter.unavailableCalls.isEmpty)
    }

    @Test("a wrong decryption key is reported neither way")
    func confirmKey_invalidKey_reportsNothing() async {
        let reporter = MockFolderLinkResolutionReporter()
        let sut = FolderLinkViewModelTests.makeSUT(
            folderLinkFlowUseCase: MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .failure(.invalidDecryptionKey)),
            linkResolutionReporter: reporter
        )

        await sut.confirmDecryptionKey("bad-key")

        #expect(reporter.resolvedCalls.isEmpty)
        #expect(reporter.unavailableCalls.isEmpty)
    }

    // MARK: - Helpers
    private static func makeSUT(
        folderLinkFlowUseCase: MockFolderLinkFlowUseCase = MockFolderLinkFlowUseCase(),
        folderLinkBuilder: MockFolderlinkBuilder = MockFolderlinkBuilder(),
        folderLinkLogoutPolicy: MockFolderLinkLogoutPolicy = MockFolderLinkLogoutPolicy(),
        networkUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase(),
        pendingConnectionsRetryUseCase: MockFolderLinkPendingConnectionsRetryUseCase = MockFolderLinkPendingConnectionsRetryUseCase(),
        tracker: MockTracker = MockTracker(),
        accountUseCase: MockAccountUseCase = MockAccountUseCase(),
        isLinkRevampEnabled: Bool = true,
        linkResolutionReporter: MockFolderLinkResolutionReporter = MockFolderLinkResolutionReporter(),
        receivedLink: String = "some_link"
    ) -> FolderLinkViewModel {
        let dependency = FolderLinkViewModel.Dependency(
            link: "some_link",
            folderLinkBuilder: folderLinkBuilder,
            folderLinkLogoutPolicy: folderLinkLogoutPolicy,
            folderLinkFlowUseCase: folderLinkFlowUseCase,
            pendingConnectionsRetryUseCase: pendingConnectionsRetryUseCase,
            networkUseCase: networkUseCase,
            isLinkRevampEnabled: isLinkRevampEnabled,
            linkResolutionReporter: linkResolutionReporter,
            receivedLink: receivedLink
        )
        return FolderLinkViewModel(dependency: dependency, tracker: tracker, accountUseCase: accountUseCase)
    }
}
