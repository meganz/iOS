import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

class DownloadNodeUseCaseTests: XCTestCase {
    func testDownloadNode_folderNamedInboxError() async {
        let nodeRepo = MockNodeRepository(node: NodeEntity(name: "Inbox", isFile: false))
        
        let mockError: TransferErrorEntity = .inboxFolderNameNotAllowed
        let sut = DownloadNodeUseCase(
            downloadFileRepository: MockDownloadFileRepository(),
            fileSystemRepository: MockFileSystemRepository(),
            nodeRepository: nodeRepo,
            nodeDataRepository: MockNodeDataRepository.newRepo,
            fileCacheRepository: MockFileCacheRepository(),
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            chatNodeRepository: MockChatNodeRepository(),
            downloadChatRepository: MockDownloadChatRepository()
        )
        
        do {
            let downloadStream = try sut.downloadFileToOffline(
                forNodeHandle: .invalid,
                filename: nil,
                appData: nil,
                startFirst: false
            )
            
            for await event in downloadStream {
                if case .finish = event {
                    XCTFail("Folder nodes named 'Inbox' could not be saved in Documents folder, should return \(mockError) error")
                }
            }
            
        } catch {
            XCTAssertEqual(error as? TransferErrorEntity, mockError)
        }
    }
    
    func testDownloadNode_downloadSuccess() async throws {
        let nodeRepo = MockNodeRepository(node: NodeEntity(base64Handle: "base64Handle"))
        let nodeDataRepo = MockNodeDataRepository(size: 10)
        let fileSystemRepo = MockFileSystemRepository()
        let mockTransferEntity = TransferEntity(type: .download, path: "Documents/")
        let downloadRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = DownloadNodeUseCase(
            downloadFileRepository: downloadRepo,
            fileSystemRepository: fileSystemRepo,
            nodeRepository: nodeRepo,
            nodeDataRepository: nodeDataRepo,
            fileCacheRepository: MockFileCacheRepository(),
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            chatNodeRepository: MockChatNodeRepository(),
            downloadChatRepository: MockDownloadChatRepository()
        )
        let downloadStream = try sut.downloadFileToOffline(
            forNodeHandle: .invalid,
            filename: nil,
            appData: nil,
            startFirst: false
        )
        
        for await event in downloadStream {
            if case .finish(let transferEntity) = event {
                XCTAssertEqual(transferEntity.path, "Documents/")
                XCTAssertEqual(transferEntity.type, .download)
            }
        }
    }

    /// An already resolved node -- an album link's photo, say -- is not in the account tree, so unlike the
    /// lookup by handle this must not consult the node repository: an empty one here would fail it if so.
    func testDownloadNodeEntity_downloadSuccess() async throws {
        let mockTransferEntity = TransferEntity(type: .download, path: "Documents/")
        let sut = makeSUT(
            downloadFileRepository: MockDownloadFileRepository(completionResult: .success(mockTransferEntity)),
            nodeRepository: MockNodeRepository()
        )
        
        let downloadStream = try sut.downloadFileToOffline(
            NodeEntity(name: "photo.jpg", handle: 5, base64Handle: "base64Handle", isFile: true),
            filename: nil,
            appData: nil,
            startFirst: false
        )
        
        for await event in downloadStream {
            if case .finish(let transferEntity) = event {
                XCTAssertEqual(transferEntity.path, "Documents/")
                XCTAssertEqual(transferEntity.type, .download)
            }
        }
    }
    
    // MARK: - Download to temp folder

    /// The batch keeps the destination the legacy path used, the node's own folder inside the temp
    /// folder, so the path the preview screens read back from the finished transfer does not move.
    func testDownloadFileToTempFolder_batchFlagOn_startsOneItemBatchInNodeTempFolder() throws {
        let downloadFileRepository = MockDownloadFileRepository()
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: MockFileCacheRepository(base64Handle: "base64Handle")
        )

        try withBatchDownloadFlag(true) {
            _ = try sut.downloadFileToTempFolder(
                node: NodeEntity(handle: 5, base64Handle: "base64Handle"),
                appData: "appData"
            )
        }

        let batch = try XCTUnwrap(downloadFileRepository.startedDownloadBatches.first)
        let item = try XCTUnwrap(batch.first)
        XCTAssertEqual(batch.count, 1)
        guard case .node(let handle) = item.source else {
            return XCTFail("The batch item should download the node itself")
        }
        XCTAssertEqual(handle, 5)
        XCTAssertEqual(item.destination, .folder(URL(fileURLWithPath: "temp/").appendingPathComponent("base64Handle")))
        XCTAssertEqual(item.appData, "appData")
        XCTAssertTrue(item.startFirst)
        XCTAssertTrue(downloadFileRepository.downloadToCalls.isEmpty, "The legacy single download should not run too")
    }

    func testDownloadFileToTempFolder_batchFlagOff_downloadsThroughLegacySingleDownload() throws {
        let downloadFileRepository = MockDownloadFileRepository()
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: MockFileCacheRepository(base64Handle: "base64Handle")
        )

        try withBatchDownloadFlag(false) {
            _ = try sut.downloadFileToTempFolder(
                node: NodeEntity(handle: 5, base64Handle: "base64Handle"),
                appData: "appData"
            )
        }

        XCTAssertEqual(
            downloadFileRepository.downloadToCalls,
            [.init(url: URL(fileURLWithPath: "temp/"), nodeHandle: 5, appData: "appData")]
        )
        XCTAssertTrue(downloadFileRepository.startedDownloadBatches.isEmpty, "No batch should start with the flag off")
    }

    /// The flag is a global, so it is put back even when the body fails.
    private func withBatchDownloadFlag(_ isEnabled: Bool, body: () throws -> Void) rethrows {
        let previous = BatchDownloadFeatureFlag.isEnabled
        BatchDownloadFeatureFlag.isEnabled = isEnabled
        defer { BatchDownloadFeatureFlag.isEnabled = previous }
        try body()
    }

    private func makeSUT(
        downloadFileRepository: MockDownloadFileRepository = MockDownloadFileRepository(),
        fileSystemRepository: MockFileSystemRepository = MockFileSystemRepository(),
        nodeRepository: MockNodeRepository = MockNodeRepository(),
        fileCacheRepository: MockFileCacheRepository = MockFileCacheRepository()
    ) -> some DownloadNodeUseCaseProtocol {
        DownloadNodeUseCase(
            downloadFileRepository: downloadFileRepository,
            fileSystemRepository: fileSystemRepository,
            nodeRepository: nodeRepository,
            nodeDataRepository: MockNodeDataRepository.newRepo,
            fileCacheRepository: fileCacheRepository,
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            chatNodeRepository: MockChatNodeRepository(),
            downloadChatRepository: MockDownloadChatRepository()
        )
    }
}
