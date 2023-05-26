import MEGADomainMock
import MEGADomain
import XCTest

final class TransferRepositoryTests: XCTestCase {
    private let sut = MockTransferRepository.newRepo
    
    func testTransferDownload() async throws {
        let node = NodeEntity(handle: 1234)
        let transfer = try await sut.download(node: node, to: URL(fileURLWithPath: "/path"))
        XCTAssertEqual(node.handle, transfer.nodeHandle)
        XCTAssertEqual("/path", transfer.path)
    }
    
    func testTransferUpload() async throws {
        let parent = NodeEntity(handle: 12345)
        let transfer = try await sut.uploadFile(at: URL(fileURLWithPath: "/path/file.txt"), to: parent)
        XCTAssertEqual(transfer.parentHandle, parent.handle)
    }
}
