import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("OfflineUseCase Tests - Validates OfflineUseCase functionality")
struct OfflineUseCaseTests {
    private static let documentsURL = URL(string: "file:///data/Containers/Data/Application/3EAE35E8-ABD4-49DE-90C9-C1070C22A6E1/Documents")!
    private static let testURL = documentsURL.appendingPathComponent("photos/readme.md")
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
        @Test("When the item is inside the offline directory, should remove it")
        func withItemInsideOfflineDirectory_shouldRemoveItem() async throws {
            let (sut, fileSystemRepository, _) = makeSUT(offlineDirectoryURL: documentsURL)
            try await sut.removeItem(at: testURL)
            #expect(fileSystemRepository.removeFileURLs == [testURL])
        }

        @Test("When the item is a top-level offline item kept under its escaped name, should remove it")
        func withEscapedTopLevelItem_shouldRemoveItem() async throws {
            let escapedURL = documentsURL.appendingPathComponent("%2e%2e")
            let (sut, fileSystemRepository, _) = makeSUT(offlineDirectoryURL: documentsURL)
            try await sut.removeItem(at: escapedURL)
            #expect(fileSystemRepository.removeFileURLs == [escapedURL])
        }

        @Test(
            "When the URL resolves to the offline directory or outside it, should throw and remove nothing",
            arguments: [
                "..",
                "../Library",
                "photos/../..",
                ".",
                ""
            ]
        )
        func withURLOutsideOfflineDirectory_shouldThrowWithoutRemoving(pathComponent: String) async throws {
            let url = documentsURL.appendingPathComponent(pathComponent)
            let (sut, fileSystemRepository, _) = makeSUT(offlineDirectoryURL: documentsURL)

            await #expect(throws: OfflineErrorEntity.itemOutsideOfflineDirectory) {
                try await sut.removeItem(at: url)
            }
            #expect(fileSystemRepository.removeFileURLs.isEmpty)
        }

        @Test("When the offline directory is unknown, should throw and remove nothing")
        func withUnknownOfflineDirectory_shouldThrowWithoutRemoving() async throws {
            let (sut, fileSystemRepository, _) = makeSUT(offlineDirectoryURL: nil)

            await #expect(throws: OfflineErrorEntity.itemOutsideOfflineDirectory) {
                try await sut.removeItem(at: testURL)
            }
            #expect(fileSystemRepository.removeFileURLs.isEmpty)
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
            let updates: [TransferResponseEntity] = [
                TransferResponseEntity(transferEntity: TransferEntity(type: .download), error: ErrorEntity(type: .ok)),
                TransferResponseEntity(transferEntity: TransferEntity(type: .upload), error: ErrorEntity(type: .ok)),
                TransferResponseEntity(transferEntity: TransferEntity(type: .download), error: ErrorEntity(type: .badArguments))
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
