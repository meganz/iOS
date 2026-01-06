import FolderLink
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

struct FolderLinkFetchNodesUseCaseTests {
    @Test("fetch nodes succeeds")
    func fetchNodesDoesNotThrowWhenSuccess() async throws {
        let repo = MockFolderLinkRepository()
        let sut = FolderLinkFetchNodesUseCase(folderLinkRepository: repo)
        await #expect(throws: Never.self) {
            try await sut.fetchNodes()
        }
    }

    @Test("fetch nodes rethrows known domain error")
    func fetchNodesThrowsWhenFailure() async {
        let error = MockError()
        let repo = MockFolderLinkRepository(fetchNodesResult: .failure(error))
        let sut = FolderLinkFetchNodesUseCase(folderLinkRepository: repo)
        await #expect(throws: FolderLinkFetchNodesErrorEntity.linkUnavailable(.generic)) {
            try await sut.fetchNodes()
        }
    }
}
