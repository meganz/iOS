import FolderLink
import MEGADomain
import MEGADomainMock
import Testing

@Suite("FolderLinkViewModel Tests")
@MainActor
struct FolderLinkViewModelTests {
    @Test("start success sets results state")
    func start_success_setsResults() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .success(123))
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
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .success(123))
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

    // MARK: - Helpers
    private static func makeSUT(
        folderLinkFlowUseCase: MockFolderLinkFlowUseCase = MockFolderLinkFlowUseCase(),
        folderLinkBuilder: MockFolderlinkBuilder = MockFolderlinkBuilder(),
        networkUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase(),
        pendingConnectionsRetryUseCase: MockFolderLinkPendingConnectionsRetryUseCase = MockFolderLinkPendingConnectionsRetryUseCase()
    ) -> FolderLinkViewModel {
        let dependency = FolderLinkViewModel.Dependency(
            link: "some_link",
            folderLinkBuilder: folderLinkBuilder,
            folderLinkFlowUseCase: folderLinkFlowUseCase,
            pendingConnectionsRetryUseCase: pendingConnectionsRetryUseCase,
            networkUseCase: networkUseCase
        )
        return FolderLinkViewModel(dependency: dependency)
    }
}
