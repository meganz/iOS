import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("OfflineUseCase Tests - Validates OfflineUseCase functionality")
struct OfflineUseCaseTests {
    private let testURL = URL(string: "file:///data/Containers/Data/Application/3EAE35E8-ABD4-49DE-90C9-C1070C22A6E1/Documents/photos/readme.md")!
    private let expectedRelativePath = "photos/readme.md"

    private func makeSUT(
        relativePath: String? = nil,
        offlineFileEntities: [OfflineFileEntity] = [],
        offlineFileEntity: OfflineFileEntity? = nil
    ) -> (
        sut: OfflineUseCase,
        fileSystemRepository: MockFileSystemRepository,
        offlineFilesRepository: MockOfflineFilesRepository
    ) {
        let fileSystemRepository = MockFileSystemRepository(relativePath: relativePath ?? expectedRelativePath)
        let offlineFilesRepository = MockOfflineFilesRepository(
            offlineFileEntities: offlineFileEntities,
            offlineFileEntity: offlineFileEntity
        )
        let sut = OfflineUseCase(
            fileSystemRepository: fileSystemRepository,
            offlineFilesRepository: offlineFilesRepository
        )
        return (sut, fileSystemRepository, offlineFilesRepository)
    }

    @Test("relativePathToDocumentsDirectory should return expected path")
    func relativePathToDocumentsDirectory_shouldReturnExpectedPath() {
        let (sut, _, _) = makeSUT(relativePath: expectedRelativePath)

        let result = sut.relativePathToDocumentsDirectory(for: testURL)

        #expect(result == expectedRelativePath, "Expected \(expectedRelativePath), but got \(result)")
    }

    @Test("removeItem should successfully remove the item")
    func removeItem_whenSuccess_shouldRemoveTheItem() async throws {
        let (sut, fileSystemRepository, _) = makeSUT()

        try await sut.removeItem(at: testURL)

        #expect(fileSystemRepository.removeFileURLs == [testURL], "Expected file removal for \(testURL)")
    }

    @Test("removeAllOfflineFiles should invoke repository correctly")
    func removeAllOfflineFiles_whenCalled_shouldInvokeRepository() async throws {
        let (sut, _, offlineFilesRepository) = makeSUT()

        try await sut.removeAllOfflineFiles()

        #expect(offlineFilesRepository.removeAllOfflineNodesCalledTimes == 1, "Expected removeAllOfflineNodes to be called exactly once.")
    }
}
