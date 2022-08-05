import XCTest
@testable import MEGA
import MEGADomain

class DownloadNodeUseCaseTests: XCTestCase {
    func testDownloadNode_fileAlreadyInOfflineError() {
        let nodeRepo = MockNodeRepository(base64Handle: "base64Handle", isFile: true)
        let offlineNode = OfflineFileEntity(base64Handle: "base64Handle", localPath: "Documents/", parentBase64Handle: nil, fingerprint: nil, timestamp: nil)
        let offlineFilesRepo = MockOfflineFilesRepository(offlineFileMock: offlineNode)
        
        let mockError: TransferErrorEntity = .alreadyDownloaded
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: offlineFilesRepo, fileSystemRepository: MockFileSystemRepository(), nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository())
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, cancelToken: MEGACancelToken(), start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Nodes already in offline, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        }
    }
    
    func testDownloadNode_copiedFromTempFolderError() {
        let nodeRepo = MockNodeRepository(name: "nodeName", size: 10, base64Handle: "base64Handle", isFile: true, copiedNodeIfExists: false)
        let fileSytemRepo = MockFileSystemRepository(sizeAvailability: 100, fileExists: true, copiedNode: true)
        
        let mockError: TransferErrorEntity = .copiedFromTempFolder
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: fileSytemRepo, nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository())
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, cancelToken: MEGACancelToken(), start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Nodes copied from temp folder, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        }
    }
    
    func testDownloadNode_folderNamedInboxError() {
        let nodeRepo = MockNodeRepository(name: "Inbox", isFile: false)
        
        let mockError: TransferErrorEntity = .inboxFolderNameNotAllowed
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: MockFileSystemRepository(), nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository())
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, cancelToken: MEGACancelToken(), start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Folder nodes named 'Inbox' could not be saved in Documents folder, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        }
    }
    
    func testDownloadNode_notEnoughSpaceError() {
        let nodeRepo = MockNodeRepository(name: "node", size: 1000)
        let fileSytemRepo = MockFileSystemRepository(sizeAvailability: 100)

        let mockError: TransferErrorEntity = .notEnoughSpace
        let sut = DownloadNodeUseCase(downloadFileRepository: MockDownloadFileRepository(), offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: fileSytemRepo, nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository())
        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, cancelToken: MEGACancelToken(), start: nil, update: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Folder nodes named 'Inbox' could not be saved in Documents folder, should return \(mockError) error")
            case .failure(let error):
                XCTAssertEqual(error, mockError)
            }
        }
    }
    
    func testDownloadNode_downloadSuccess() {
        let nodeRepo = MockNodeRepository(size: 10, base64Handle: "base64Handle", isFile: true)
        let fileSytemRepo = MockFileSystemRepository(sizeAvailability: 100)
        let mockTransferEntity = TransferEntity(type: .download, path: "Documents/")
        let downloadRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = DownloadNodeUseCase(downloadFileRepository: downloadRepo, offlineFilesRepository: MockOfflineFilesRepository(), fileSystemRepository: fileSytemRepo, nodeRepository: nodeRepo, fileCacheRepository: MockFileCacheRepository())

        sut.downloadFileToOffline(forNodeHandle: .invalid, filename: nil, appdata: nil, startFirst: false, cancelToken: MEGACancelToken(), start: nil, update: nil) { result in
            switch result {
            case .success(let transferEntity):
                XCTAssertEqual(transferEntity.path, "Documents/")
                XCTAssertEqual(transferEntity.type, .download)
            case .failure(let error):
                XCTFail("Not expected error: \(error)")
            }
        }
    }
}
