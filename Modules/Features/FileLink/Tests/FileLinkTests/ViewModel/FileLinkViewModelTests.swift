import FileLink
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@Suite("FileLinkViewModel Tests")
@MainActor
struct FileLinkViewModelTests {
    @Test("a resolved link shows its node")
    func startLoading_success_showsNode() async {
        let sut = makeSUT(
            fileLinkFlowUseCase: MockFileLinkFlowUseCase(initialStartResult: .success(NodeEntity(handle: 42)))
        )

        await sut.startLoadingFileLink()

        #expect(sut.viewState == .loaded(NodeEntity(handle: 42)))
    }

    @Test("the file takes over the navigation bar once the link resolves")
    func navigationTitle_afterLoading_isFileName() async {
        let sut = makeSUT(
            fileLinkFlowUseCase: MockFileLinkFlowUseCase(
                initialStartResult: .success(NodeEntity(name: "elcapitan.jpeg", handle: 42))
            )
        )

        await sut.startLoadingFileLink()

        #expect(sut.navigationTitle == "elcapitan.jpeg")
        #expect(sut.navigationSubtitle == Strings.Localizable.fileLink)
    }

    @Test("while the link is being resolved the navigation bar carries the brand")
    func navigationTitle_whileLoading_isBrand() {
        let sut = makeSUT()

        #expect(sut.navigationTitle == "MEGA")
        #expect(sut.navigationSubtitle == Strings.Localizable.fileLink)
    }

    /// As in the folder link, the failure is spelled out by the empty state, not by the title.
    @Test("an unavailable link keeps the brand in the navigation bar")
    func navigationTitle_onError_isBrand() async {
        let sut = makeSUT(
            fileLinkFlowUseCase: MockFileLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(.expired)))
        )

        await sut.startLoadingFileLink()

        #expect(sut.navigationTitle == "MEGA")
        #expect(sut.navigationSubtitle == Strings.Localizable.fileLink)
    }

    @Test("a link shared without its key asks for the decryption key")
    func startLoading_missingKey_asksForDecryptionKey() async {
        let sut = makeSUT(
            fileLinkFlowUseCase: MockFileLinkFlowUseCase(initialStartResult: .failure(.missingDecryptionKey))
        )

        await sut.startLoadingFileLink()

        #expect(sut.askingForDecryptionKey == true)
        #expect(sut.viewState == .loading)
    }

    @Test("an unavailable link shows the unavailable state with its reason")
    func startLoading_unavailable_setsErrorState() async {
        let sut = makeSUT(
            fileLinkFlowUseCase: MockFileLinkFlowUseCase(initialStartResult: .failure(.linkUnavailable(.downETD)))
        )

        await sut.startLoadingFileLink()

        #expect(sut.viewState == .error(.downETD))
    }

    @Test("confirming a decryption key shows the node it resolves")
    func confirmDecryptionKey_success_showsNode() async {
        let fileLinkFlowUseCase = MockFileLinkFlowUseCase(
            confirmDecryptionKeyResult: .success(NodeEntity(handle: 42))
        )
        let sut = makeSUT(fileLinkFlowUseCase: fileLinkFlowUseCase)

        await sut.confirmDecryptionKey("key")

        #expect(fileLinkFlowUseCase.confirmDecryptionKeyCalledArguments.map(\.decryptionKey) == ["key"])
        #expect(sut.viewState == .loaded(NodeEntity(handle: 42)))
    }

    @Test("an invalid decryption key is reported without leaving the loading state")
    func confirmDecryptionKey_invalidKey_notifiesInvalidKey() async {
        let sut = makeSUT(
            fileLinkFlowUseCase: MockFileLinkFlowUseCase(confirmDecryptionKeyResult: .failure(.invalidDecryptionKey))
        )

        await sut.confirmDecryptionKey("key")

        #expect(sut.notifyInvalidDecryptionKey == true)
        #expect(sut.askingForDecryptionKey == false)
        #expect(sut.viewState == .loading)
    }

    @Test("a link that resolves after the screen was closed is not shown")
    func closedWhileLoading_success_doesNothing() async {
        let fileLinkFlowUseCase = MockFileLinkFlowUseCase(initialStartResult: .success(NodeEntity(handle: 42)))
        let sut = makeSUT(fileLinkFlowUseCase: fileLinkFlowUseCase)
        fileLinkFlowUseCase.whileInFlight = { sut.stopLoadingFileLink() }

        await sut.startLoadingFileLink()

        #expect(sut.viewState == .loading)
    }

    @Test("an error that arrives after the screen was closed leaves the state alone")
    func closedWhileLoading_error_keepsState() async {
        let fileLinkFlowUseCase = MockFileLinkFlowUseCase(
            initialStartResult: .failure(.linkUnavailable(.generic))
        )
        let sut = makeSUT(fileLinkFlowUseCase: fileLinkFlowUseCase)
        fileLinkFlowUseCase.whileInFlight = { sut.stopLoadingFileLink() }

        await sut.startLoadingFileLink()

        #expect(sut.viewState == .loading)
        #expect(sut.askingForDecryptionKey == false)
        #expect(sut.notifyInvalidDecryptionKey == false)
    }

    @Test("a key confirmed after the screen was closed does not show its node")
    func closedWhileConfirmingKey_success_doesNothing() async {
        let fileLinkFlowUseCase = MockFileLinkFlowUseCase(
            confirmDecryptionKeyResult: .success(NodeEntity(handle: 42))
        )
        let sut = makeSUT(fileLinkFlowUseCase: fileLinkFlowUseCase)
        fileLinkFlowUseCase.whileInFlight = { sut.stopLoadingFileLink() }

        await sut.confirmDecryptionKey("key")

        #expect(sut.viewState == .loading)
    }

    @Test("acknowledging an invalid key asks for the decryption key again")
    func acknowledgeInvalidDecryptionKey_asksForKeyAgain() async {
        let sut = makeSUT()

        sut.acknowledgeInvalidDecryptionKey()

        #expect(sut.askingForDecryptionKey == true)
    }

    private func makeSUT(
        link: String = "link",
        fileLinkFlowUseCase: MockFileLinkFlowUseCase = MockFileLinkFlowUseCase()
    ) -> FileLinkViewModel {
        FileLinkViewModel(
            dependency: FileLinkViewModel.Dependency(
                link: link,
                fileLinkFlowUseCase: fileLinkFlowUseCase
            )
        )
    }
}
