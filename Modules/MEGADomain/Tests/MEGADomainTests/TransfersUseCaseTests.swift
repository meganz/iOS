import XCTest
import MEGADomain
import MEGADomainMock

final class TransfersUseCaseTests: XCTestCase {
    func testTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.transfers(filteringUserTransfers: false).count, repo.transfers().count)
    }
    
    func testTransfers_filteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.transfers(filteringUserTransfers: true).count, 2)
    }
    
    func testDownloadTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.downloadTransfers(filteringUserTransfers: false).count, repo.downloadTransfers().count)
    }
    
    func testDownloadTransfers_filteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.downloadTransfers(filteringUserTransfers: true).count, 1)
    }
    
    func testUploadTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.uploadTransfers(filteringUserTransfers: false).count, repo.uploadTransfers().count)
    }
    
    func testUploadTransfers_filteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.uploadTransfers(filteringUserTransfers: true).count, 2)
    }
    
    func testCompletedTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.completedTransfers(filteringUserTransfers: false).count, repo.completedTransfers().count)
    }
    
    func testCompletedTransfers_filteringUserTransfers() {
        let repo = MockTransfersRepository.newRepo
        let sut = TransfersUseCase(transfersRepository: repo, fileSystemRepository: MockFileSystemRepository())
        XCTAssertEqual(sut.completedTransfers(filteringUserTransfers: true).count, 3)
    }
}

