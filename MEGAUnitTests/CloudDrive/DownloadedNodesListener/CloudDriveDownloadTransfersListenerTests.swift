@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class CloudDriveDownloadTransfersListenerTests: XCTestCase {
    class Harness {
        var offlinePath: String {
            fileSystemRepo.documentsDirectory().relativeString
        }
        let sut: CloudDriveDownloadTransfersListener
        let sdk = MockSdk(nodes: [MockNode(handle: 0), MockNode(handle: 1), MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 5)])
        let transferListenerUsecase = MockTransfersListenerUseCase()
        let fileSystemRepo = MockFileSystemRepository()
        
        init() {
            sut = CloudDriveDownloadTransfersListener(sdk: sdk, transfersListenerUsecase: transferListenerUsecase, fileSystemRepo: fileSystemRepo)
        }
    }
    
    func testdownloadedNodes_whenNodesAreDownloaded_shouldEmitCorrectNodeEntities() async {
        // given
        let harness = Harness()
        
        let inputTransfers: [TransferEntity] = [
            makeTransfer(handle: 0, isStreamingTransfer: true, type: .download, parentPath: harness.offlinePath), // will trigger signal
            makeTransfer(handle: 1, isStreamingTransfer: false, type: .download, parentPath: harness.offlinePath), // `isStreamingTransfer: false` will not trigger signal
            makeTransfer(handle: 2, isStreamingTransfer: true, type: .upload, parentPath: harness.offlinePath), // `type: .upload` will not trigger signal
            makeTransfer(handle: 3, isStreamingTransfer: true, type: .download, parentPath: "NotDownloads"), // `parentPath: "NotDownload"` will not trigger signal
            makeTransfer(handle: 4, isStreamingTransfer: true, type: .download, parentPath: harness.offlinePath), // will not trigger signal because sdk cannot find this handle
            makeTransfer(handle: 5, isStreamingTransfer: false, type: .download, parentPath: harness.offlinePath) // will trigger signal
        ]
        
        let expectedOutput: [HandleEntity] = [1, 5]
        
        // when
        let exp = expectation(description: "Waiting for downloadedNodes")
        exp.expectedFulfillmentCount = expectedOutput.count
        
        let task = Task {
            var expectedOutput = expectedOutput
            for await node in harness.sut.downloadedNodes {
                // then
                XCTAssertEqual(node.handle, expectedOutput.removeFirst())
                exp.fulfill()
            }
        }
        
        inputTransfers.forEach {
            harness.transferListenerUsecase.simulateTransfer($0)
        }
        
        await fulfillment(of: [exp], timeout: 0.5)
        task.cancel()
    }
    
    private func makeTransfer(
        handle: UInt64, 
        isStreamingTransfer: Bool,
        type: TransferTypeEntity,
        parentPath: String?
    ) -> TransferEntity {
        .init(type: type, parentPath: parentPath, nodeHandle: handle, isStreamingTransfer: isStreamingTransfer)
    }
}
