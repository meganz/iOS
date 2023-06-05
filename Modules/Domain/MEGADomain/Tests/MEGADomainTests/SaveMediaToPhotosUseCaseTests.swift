import XCTest
import MEGADomain
import MEGADomainMock

final class SaveMediaToPhotosUseCaseTests: XCTestCase {
    private let nodeEntity = NodeEntity(name: "nodeName")
    private let nodeEntity2 = NodeEntity(name: "node2")
    private let mockTransferEntity = TransferEntity(path: "originalV3/" + "123")
    private var mockNodeRepo: MockNodeRepository!
    private var mockDownloadFileRepo: MockDownloadFileRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockNodeRepo = MockNodeRepository(node: nodeEntity)
    }
    
    func testSaveToPhotos_single_succeeded() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        
        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo)
        try await sut.saveToPhotos(nodes: [nodeEntity])
    }
    
    func testSaveToPhotos_single_failed() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .failure(.download))
        
        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo)
        do {
            try await sut.saveToPhotos(nodes: [nodeEntity])
        } catch let errorEntity as SaveMediaToPhotosErrorEntity {
            XCTAssertTrue(errorEntity == .fileDownloadInProgress)
        }
    }
    
    func testSaveToPhotos_multiple_succeeded() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        
        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo)
        try await sut.saveToPhotos(nodes: [nodeEntity, nodeEntity2])
    }
    
    func testSaveToPhotos_multiple_failed() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .failure(.download))
        
        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo)
        do {
            try await sut.saveToPhotos(nodes: [nodeEntity, nodeEntity2])
        } catch let errorEntity as SaveMediaToPhotosErrorEntity {
            XCTAssertTrue(errorEntity == .fileDownloadInProgress)
        }
    }
}
