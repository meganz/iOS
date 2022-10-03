import XCTest
import MEGADomain
import MEGADomainMock

class DownloadNodeUseCaseTests: XCTestCase {
    func testDownloadNode_fileAlreadyInOfflineError() {
        let nodeRepo = MockNodeRepository(node: NodeEntity(base64Handle: "base64Handle", isFile: true))
        let offlineNode = OfflineFileEntity(base64Handle: "base64Handle", localPath: "Documents/", parentBase64Handle: nil, fingerprint: nil, timestamp: nil)
        let offlineFilesRepo = MockOfflineFilesRepository(offlineFileEntity: offlineNode)
        
        let mockError: TransferErrorEntity = .alreadyDownloaded
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: offlineFilesRepo, fileSystemRepository: MockFileSystemRepository(), nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository(), mediaUseCase: MockMediaUseCase(), preferenceRepository: EmptyPreferenceRepository.newRepo)
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Nodes already in offline, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        } folderUpdate: { _ in }
    }
    
    func testDownloadNode_copiedFromTempFolderError() {
        let nodeRepo = MockNodeRepository(node: NodeEntity(name: "nodeName", base64Handle: "base64Handle", isFile: true, size: 10), copiedNodeIfExists: false)
        let fileSytemRepo = MockFileSystemRepository(sizeAvailability: 100, fileExists: true, copiedNode: true)
        
        let mockError: TransferErrorEntity = .copiedFromTempFolder
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: fileSytemRepo, nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository(), mediaUseCase: MockMediaUseCase(), preferenceRepository: EmptyPreferenceRepository.newRepo)
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Nodes copied from temp folder, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        } folderUpdate: { _ in }
    }
    
    func testDownloadNode_folderNamedInboxError() {
        let nodeRepo = MockNodeRepository(node: NodeEntity(name: "Inbox", isFile: false))
        
        let mockError: TransferErrorEntity = .inboxFolderNameNotAllowed
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: MockFileSystemRepository(), nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository(), mediaUseCase: MockMediaUseCase(), preferenceRepository: EmptyPreferenceRepository.newRepo)
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Folder nodes named 'Inbox' could not be saved in Documents folder, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        } folderUpdate: { _ in }
    }
    
    func testDownloadNode_notEnoughSpaceError() {
        let nodeRepo = MockNodeRepository(node: NodeEntity(name: "node", size: 1000))
        let fileSytemRepo = MockFileSystemRepository(sizeAvailability: 100)

        let mockError: TransferErrorEntity = .notEnoughSpace
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: fileSytemRepo, nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository(), mediaUseCase: MockMediaUseCase(), preferenceRepository: EmptyPreferenceRepository.newRepo)
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Folder nodes named 'Inbox' could not be saved in Documents folder, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        } folderUpdate: { _ in }
    }
    
    func testDownloadNode_downloadSuccess() {
        let nodeRepo = MockNodeRepository(node: NodeEntity(base64Handle: "base64Handle"), size: 10, isFile: true)
        let fileSytemRepo = MockFileSystemRepository(sizeAvailability: 100)
        let mockTransferEntity = TransferEntity(type: .download, path: "Documents/")
        let downloadRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = DownloadNodeUseCase(downloadFileRepository: downloadRepo, offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: fileSytemRepo, nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository(), mediaUseCase: MockMediaUseCase(), preferenceRepository: EmptyPreferenceRepository.newRepo)

        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, start: nil, update: nil) { result in
            switch result {
            case .success(let transferEntity):
                XCTAssertEqual(transferEntity.path, "Documents/")
                XCTAssertEqual(transferEntity.type, .download)
            case .failure(let error):
                XCTFail("Not expected error: \(error)")
            }
        } folderUpdate: { _ in }
    }
}
