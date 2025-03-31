import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("OfflineUseCase Tests - Validates OfflineUseCase functionality")
struct OfflineUseCaseTests {
    private static let testURL = URL(string: "file:///data/Containers/Data/Application/3EAE35E8-ABD4-49DE-90C9-C1070C22A6E1/Documents/photos/readme.md")!
    private static let invalidURL = URL(string: "invalid://path")!
    private static let expectedRelativePath = "photos/readme.md"

    private static func makeSUT(
        relativePath: String? = nil,
        offlineSize: UInt64 = 0,
        offlineDirectoryURL: URL? = nil,
        nodeTransferRepository: MockNodeTransferRepository = MockNodeTransferRepository()
    ) -> (
        sut: OfflineUseCase,
        fileSystemRepository: MockFileSystemRepository,
        offlineFilesRepository: MockOfflineFilesRepository
    ) {
        let fileSystemRepository = MockFileSystemRepository(
            relativePath: relativePath ?? "",
            offlineDirectoryURL: offlineDirectoryURL
        )
        let offlineFilesRepository = MockOfflineFilesRepository(offlineSize: offlineSize)
        let sut = OfflineUseCase(
            fileSystemRepository: fileSystemRepository,
            offlineFilesRepository: offlineFilesRepository,
            nodeTransferRepository: nodeTransferRepository
        )
        return (sut, fileSystemRepository, offlineFilesRepository)
    }

    @Suite("OfflineUseCase relativePath Tests")
    struct RelativePathTests {
        @Test("When given a valid URL, should return expected path")
        func withValidURL_shouldReturnExpectedPath() {
            let (sut, _, _) = makeSUT(relativePath: expectedRelativePath)
            let result = sut.relativePathToDocumentsDirectory(for: testURL)
            #expect(result == expectedRelativePath)
        }

        @Test("When given an invalid URL, should return empty string")
        func withInvalidURL_shouldReturnEmptyString() {
            let (sut, _, _) = makeSUT()
            let result = sut.relativePathToDocumentsDirectory(for: invalidURL)
            #expect(result.isEmpty)
        }
    }

    @Suite("OfflineUseCase removeItem Tests")
    struct RemoveItemTests {
        @Test("When file exists, should remove the item")
        func withExistingFile_shouldRemoveItem() async throws {
            let (sut, fileSystemRepository, _) = makeSUT()
            try await sut.removeItem(at: testURL)
            #expect(fileSystemRepository.removeFileURLs == [testURL])
        }
    }

    @Suite("OfflineUseCase removeAllOfflineFiles Tests")
    struct RemoveAllOfflineFilesTests {
        @Test("When offline directory exists, should remove all files")
        func withOfflineDirectory_shouldRemoveAllFiles() async throws {
            let (sut, fileSystemRepository, _) = makeSUT(offlineDirectoryURL: testURL)
            try await sut.removeAllOfflineFiles()
            #expect(fileSystemRepository.removeFolderContents_calledTimes == 1)
        }

        @Test("When offline directory is nil, should not throw error")
        func withNilOfflineDirectory_shouldNotThrowError() async throws {
            let (sut, _, _) = makeSUT()
            
            await #expect(throws: Never.self) {
                try await sut.removeAllOfflineFiles()
            }
        }
    }

    @Suite("OfflineUseCase removeAllStoredFiles Tests")
    struct RemoveAllStoredFilesTests {
        @Test("Should clear all stored offline nodes")
        func shouldClearAllStoredNodes() {
            let (sut, _, offlineFilesRepository) = makeSUT()
            sut.removeAllStoredFiles()
            #expect(offlineFilesRepository.removeAllOfflineNodesCalledTimes == 1)
        }
    }

    @Suite("OfflineUseCase offlineSize Tests")
    struct OfflineSizeTests {
        @Test("Should return correct total size")
        func shouldReturnCorrectTotalSize() {
            let expectedSize: UInt64 = 1024 * 1024 * 50
            let (sut, _, _) = makeSUT(offlineSize: expectedSize)
            let result = sut.offlineSize()
            #expect(result == expectedSize)
        }
    }

    @Suite("Node Download Completion Updates")
    struct NodeDownloadCompletionUpdates {
        @Test func shouldYieldUpdatesDownloadOnly() async throws {
            let updates: [Result<TransferEntity, ErrorEntity>] = [
                .success(TransferEntity(type: .download, nodeHandle: 1)),
                .success(TransferEntity(type: .upload, nodeHandle: 2)),
                .failure(ErrorEntity(type: .badArguments, name: "", value: 1))
            ]
            
            let nodeTransferRepository = MockNodeTransferRepository(transferFinishUpdates: updates.async.eraseToAnyAsyncSequence())
            let (sut, _, _) = makeSUT(nodeTransferRepository: nodeTransferRepository)
            
            var updatesCount = 0
            for await _ in sut.nodeDownloadCompletionUpdates {
                updatesCount += 1
            }
            
            #expect(updatesCount == 1)
        }
    }
}
