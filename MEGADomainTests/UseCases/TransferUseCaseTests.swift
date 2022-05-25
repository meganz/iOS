
import XCTest
@testable import MEGA

final class TransferUseCaseTests: XCTestCase {
    func testTransfers_withoutFilteringUserTransfers() async {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        let transfersCount = await sut.transfers(filteringUserTransfers: false).count
        XCTAssertEqual(transfersCount, repo.transfers().count)
    }
    
    func testTransfers_filteringUserTransfers() async {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        let transfersCount = await sut.transfers(filteringUserTransfers: true).count
        XCTAssertEqual(transfersCount, 2)
    }
    
    func testDownloadTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        XCTAssertEqual(sut.downloadTransfers(filteringUserTransfers: false).count, repo.downloadTransfers().count)
    }
    
    func testDownloadTransfers_filteringUserTransfers() {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        XCTAssertEqual(sut.downloadTransfers(filteringUserTransfers: true).count, 1)
    }
    
    func testUploadTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        XCTAssertEqual(sut.uploadTransfers(filteringUserTransfers: false).count, repo.uploadTransfers().count)
    }
    
    func testUploadTransfers_filteringUserTransfers() {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        XCTAssertEqual(sut.uploadTransfers(filteringUserTransfers: true).count, 2)
    }
    
    func testCompletedTransfers_withoutFilteringUserTransfers() {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        XCTAssertEqual(sut.completedTransfers(filteringUserTransfers: false).count, repo.completedTransfers().count)
    }
    
    func testCompletedTransfers_filteringUserTransfers() {
        let repo = MockTransferRepository()
        let sut = TransfersUseCase(repo: repo)
        XCTAssertEqual(sut.completedTransfers(filteringUserTransfers: true).count, 3)
    }
}

