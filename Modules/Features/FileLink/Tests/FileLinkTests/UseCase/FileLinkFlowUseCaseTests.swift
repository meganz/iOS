import FileLink
import MEGADomain
import MEGADomainMock
import Testing

@Suite("FileLinkFlowUseCase Tests")
struct FileLinkFlowUseCaseTests {
    @Test("initial start returns the resolved node")
    func initialStart_success_returnsNode() async throws {
        let sut = makeSUT(repositoryResult: .success(NodeEntity(handle: 42)))

        let node = try await sut.initialStart(with: "link")

        #expect(node.handle == 42)
    }

    @Test("initial start with a key embedded in the link shows the unavailable page when the key is invalid")
    func initialStart_invalidKey_throwsLinkUnavailable() async {
        let sut = makeSUT(repositoryResult: .failure(.invalidDecryptionKey))

        await #expect(throws: FileLinkFlowErrorEntity.linkUnavailable(.generic)) {
            try await sut.initialStart(with: "link")
        }
    }

    @Test("initial start asks for the decryption key when the link was shared without one")
    func initialStart_missingKey_throwsMissingDecryptionKey() async {
        let sut = makeSUT(repositoryResult: .failure(.missingDecryptionKey))

        await #expect(throws: FileLinkFlowErrorEntity.missingDecryptionKey) {
            try await sut.initialStart(with: "link")
        }
    }

    @Test("initial start keeps the reason the link is unavailable")
    func initialStart_unavailable_keepsReason() async {
        let sut = makeSUT(repositoryResult: .failure(.linkUnavailable(.expired)))

        await #expect(throws: FileLinkFlowErrorEntity.linkUnavailable(.expired)) {
            try await sut.initialStart(with: "link")
        }
    }

    @Test("confirming a decryption key resolves the link built around it")
    func confirmDecryptionKey_success_buildsLinkWithKey() async throws {
        let fileLinkBuilder = MockFileLinkBuilder(result: "link-with-key")
        let sut = makeSUT(
            repositoryResult: .success(NodeEntity(handle: 42)),
            fileLinkBuilder: fileLinkBuilder
        )

        let node = try await sut.confirmDecryptionKey(with: "link", decryptionKey: "key")

        #expect(node.handle == 42)
        #expect(fileLinkBuilder.buildCalledArguments.map(\.key) == ["key"])
    }

    @Test("confirming a decryption key reports an invalid key instead of the unavailable page")
    func confirmDecryptionKey_invalidKey_throwsInvalidDecryptionKey() async {
        let sut = makeSUT(repositoryResult: .failure(.invalidDecryptionKey))

        await #expect(throws: FileLinkFlowErrorEntity.invalidDecryptionKey) {
            try await sut.confirmDecryptionKey(with: "link", decryptionKey: "key")
        }
    }

    private func makeSUT(
        repositoryResult: Result<NodeEntity, FileLinkPublicNodeErrorEntity>,
        fileLinkBuilder: MockFileLinkBuilder = MockFileLinkBuilder()
    ) -> FileLinkFlowUseCase {
        FileLinkFlowUseCase(
            fileLinkRepository: MockFileLinkRepository(result: repositoryResult),
            fileLinkBuilder: fileLinkBuilder
        )
    }
}
