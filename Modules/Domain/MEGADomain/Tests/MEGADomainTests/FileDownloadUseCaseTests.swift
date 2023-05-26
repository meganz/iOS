import XCTest
import MEGADomainMock
import MEGADomain

final class FileDownloadUseCaseTests: XCTestCase {
    
    func testCachedOriginalPath_returnsNodeFileURL() {
        let node = NodeEntity(base64Handle: "123")
        let fileDownloadUseCase = FileDownloadUseCase(fileCacheRepository: MockFileCacheRepository(base64Handle: "123"),
                                                      fileSystemRepository: MockFileSystemRepository(),
                                                      downloadFileRepository: MockDownloadFileRepository())
        let path = "originalV3/" + "123"
        XCTAssertEqual(fileDownloadUseCase.cachedOriginalPath(node), URL(fileURLWithPath: path))
    }
    
    func testDownloadNode_returnsDownloadedFileURL() async throws {
        let node = NodeEntity(base64Handle: "123")
        let path = "originalV3/" + "123"
        let mockTransferEntity = TransferEntity(path: path)
        let fileDownloadUseCase = FileDownloadUseCase(fileCacheRepository: MockFileCacheRepository(base64Handle: "123"),
                                                      fileSystemRepository: MockFileSystemRepository(),
                                                      downloadFileRepository: MockDownloadFileRepository(completionResult: .success(mockTransferEntity)))
        
        let downloadNodeUrl = try await fileDownloadUseCase.downloadNode(node)
        XCTAssertEqual(downloadNodeUrl, URL(fileURLWithPath: path))
    }
}
