import FolderLink
import MEGADomain
import Testing

@Suite("FolderLinkViewModel Tests")
@MainActor
struct FolderLinkViewModelTests {
    @Test("start success sets results state")
    func start_success_setsResults() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .success(123))
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.startLoadingFolderLink()
        
        #expect(sut.viewState == .results(123))
    }

    @Test("start login requires decryption key sets askingForDecryptionKey")
    func start_loginRequiresKey_setsAsking() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .failure(.missingDecryptionKey))
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.startLoadingFolderLink()
        
        #expect(sut.viewState == .loading)
        #expect(sut.askingForDecryptionKey == true)
    }

    @Test("start generic error sets error state")
    func start_generic_setsError() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(.generic)))
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.startLoadingFolderLink()
        
        #expect(sut.viewState == .error(.generic))
    }

    @Test("confirmDecryptionKey success sets results state")
    func confirmKey_success_setsResults() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .success(123))
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.confirmDecryptionKey("key")
        #expect(sut.viewState == .results(123))
        #expect(sut.notifyInvalidDecryptionKey == false)
    }

    @Test("confirmDecryptionKey invalid key sets notifyInvalidDecryptionKey")
    func confirmKey_invalid_setsNotify() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .failure(.invalidDecryptionKey))
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.confirmDecryptionKey("bad-key")
        
        #expect(sut.viewState == .loading)
        #expect(sut.notifyInvalidDecryptionKey == true)
    }

    @Test("confirmDecryptionKey generic error sets error state")
    func confirmKey_generic_setsError() async {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase(confirmDecryptionKeyResult: .failure(.linkUnavailable(.generic)))
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        await sut.confirmDecryptionKey("some-key")
        
        #expect(sut.viewState == .error(.generic))
    }

    @Test("cancelConfirmingDecryptionKey calls stop on flow use case")
    func cancel_callsStop() {
        let folderLinkFlowUseCase = MockFolderLinkFlowUseCase()
        let sut = makeSUT(folderLinkFlowUseCase: folderLinkFlowUseCase)
        
        sut.cancelConfirmingDecryptionKey()
        
        #expect(folderLinkFlowUseCase.stopCalled == true)
    }

    @Test("acknowledgeInvalidDecryptionKey sets askingForDecryptionKey true")
    func acknowledgeInvalid_setsAskingTrue() {
        let sut = makeSUT()
        
        sut.acknowledgeInvalidDecryptionKey()
        
        #expect(sut.askingForDecryptionKey == true)
    }

    // MARK: - Helpers
    private func makeSUT(
        folderLinkFlowUseCase: MockFolderLinkFlowUseCase = MockFolderLinkFlowUseCase(),
        folderLinkBuilder: MockFolderlinkBuilder = MockFolderlinkBuilder()
    ) -> FolderLinkViewModel {
        let dependency = FolderLinkViewModel.Dependency(
            link: "some_link",
            folderLinkBuilder: folderLinkBuilder,
            folderLinkFlowUseCase: folderLinkFlowUseCase,
        )
        return FolderLinkViewModel(dependency: dependency)
    }
}
