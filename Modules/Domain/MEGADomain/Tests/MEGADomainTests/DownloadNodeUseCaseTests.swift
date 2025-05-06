import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

class DownloadNodeUseCaseTests: XCTestCase {
    func testDownloadNode_fileAlreadyInOfflineError() async {
        let nodeRepo = MockNodeRepository(node: NodeEntity(base64Handle: "base64Handle", isFile: true))
        let offlineNode = OfflineFileEntity(base64Handle: "base64Handle", localPath: "Documents/", parentBase64Handle: nil, fingerprint: nil, timestamp: nil)
        let offlineFilesRepo = MockOfflineFilesRepository(offlineFileEntity: offlineNode)
        let offlineFileFetcherRepo = MockOfflineFileFetcherRepository(offlineFileEntity: offlineNode)
        
        let mockError: TransferErrorEntity = .alreadyDownloaded
        let sut = DownloadNodeUseCase(
            downloadFileRepository: MockDownloadFileRepository(),
            offlineFilesRepository: offlineFilesRepo,
            fileSystemRepository: MockFileSystemRepository(),
            nodeRepository: nodeRepo,
            nodeDataRepository: MockNodeDataRepository.newRepo,
            fileCacheRepository: MockFileCacheRepository(),
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            offlineFileFetcherRepository: offlineFileFetcherRepo,
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
                    XCTFail("Nodes already in offline, should return \(mockError) error")
                }
            }
        } catch {
            XCTAssertEqual(error as? TransferErrorEntity, mockError)
        }
    }
    
    func testDownloadNode_copiedFromTempFolderError() async {
        let nodeRepo = MockNodeRepository(node: NodeEntity(name: "nodeName", base64Handle: "base64Handle", isFile: true, size: 10))
        let fileSystemRepo = MockFileSystemRepository(fileExists: true, copiedNode: true)
        
        let mockError: TransferErrorEntity = .copiedFromTempFolder
        let sut = DownloadNodeUseCase(
            downloadFileRepository: MockDownloadFileRepository(),
            offlineFilesRepository: MockOfflineFilesRepository(),
            fileSystemRepository: fileSystemRepo,
            nodeRepository: nodeRepo,
            nodeDataRepository: MockNodeDataRepository.newRepo,
            fileCacheRepository: MockFileCacheRepository(),
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            offlineFileFetcherRepository: MockOfflineFileFetcherRepository.newRepo,
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
                    XCTFail("Nodes copied from temp folder, should return \(mockError) error")
                }
            }
        } catch {
            XCTAssertEqual(error as? TransferErrorEntity, mockError)
        }
    }
    
    func testDownloadNode_folderNamedInboxError() async {
        let nodeRepo = MockNodeRepository(node: NodeEntity(name: "Inbox", isFile: false))
        
        let mockError: TransferErrorEntity = .inboxFolderNameNotAllowed
        let sut = DownloadNodeUseCase(
            downloadFileRepository: MockDownloadFileRepository(),
            offlineFilesRepository: MockOfflineFilesRepository(),
            fileSystemRepository: MockFileSystemRepository(),
            nodeRepository: nodeRepo,
            nodeDataRepository: MockNodeDataRepository.newRepo,
            fileCacheRepository: MockFileCacheRepository(),
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            offlineFileFetcherRepository: MockOfflineFileFetcherRepository.newRepo,
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
            offlineFilesRepository: MockOfflineFilesRepository(),
            fileSystemRepository: fileSystemRepo,
            nodeRepository: nodeRepo,
            nodeDataRepository: nodeDataRepo,
            fileCacheRepository: MockFileCacheRepository(),
            mediaUseCase: MockMediaUseCase(),
            preferenceRepository: EmptyPreferenceRepository.newRepo,
            offlineFileFetcherRepository: MockOfflineFileFetcherRepository.newRepo,
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
}
