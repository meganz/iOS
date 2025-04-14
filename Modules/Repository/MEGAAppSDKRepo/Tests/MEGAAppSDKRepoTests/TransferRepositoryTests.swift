import Foundation
@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("TransferRepository Tests")
struct TransferRepositoryTests {
    static let testFileURL = URL(fileURLWithPath: "/path")
    static let defaultNode = MockNode(handle: 1)
    static let defaultParentNode = MockNode(handle: 2)
    
    static func makeSUT(
        nodes: [MockNode],
        stubbedDownloadTransferResult: Result<MockTransfer, MockError>? = nil,
        stubbedUploadTransferResult: Result<MockTransfer, MockError>? = nil
    ) -> TransferRepository {
        let sdk = MockSdk(nodes: nodes)
        if let downloadResult = stubbedDownloadTransferResult {
            sdk.stubbedDownloadTransferResult = downloadResult
        }
        if let uploadResult = stubbedUploadTransferResult {
            sdk.stubbedUploadTransferResult = uploadResult
        }
        return TransferRepository(sdk: sdk)
    }
    
    @Suite("Download node")
    struct DownloadNodeTests {
        @Test("Download success")
        func shouldReturnTransfer() async throws {
            let sut = makeSUT(
                nodes: [defaultNode],
                stubbedDownloadTransferResult: .success(MockTransfer(nodeHandle: defaultNode.handle))
            )
            
            let transfer = try await sut.download(
                node: defaultNode.toNodeEntity(),
                to: testFileURL,
                startHandler: nil,
                progressHandler: nil
            )
            
            #expect(transfer.nodeHandle == defaultNode.handle)
        }
        
        @Test("Download fails with error")
        func shouldThrowError() async throws {
            let sut = makeSUT(
                nodes: [defaultNode],
                stubbedDownloadTransferResult: .failure(MockError(errorType: .apiEFailed))
            )
            
            await #expect(performing: {
                try await sut.download(
                    node: defaultNode.toNodeEntity(),
                    to: testFileURL,
                    startHandler: nil,
                    progressHandler: nil
                )
            }, throws: { error in
                if let errorEntity = error as? TransferErrorEntity, errorEntity == .download {
                    true
                } else {
                    false
                }
            })
        }
        
        @Test("Could not find node by handle")
        func shouldThrowCouldNotFindNodeByHandleError() async throws {
            let sut = makeSUT(nodes: [])
            
            await #expect(throws: TransferErrorEntity.couldNotFindNodeByHandle, performing: {
                try await sut.download(
                    node: defaultNode.toNodeEntity(),
                    to: testFileURL,
                    startHandler: nil,
                    progressHandler: nil
                )
            })
        }
    }
    
    @Suite("Upload node")
    struct UploadNodeTests {
        @Test("Upload success")
        func shouldReturnTransfer() async throws {
            let sut = makeSUT(
                nodes: [defaultParentNode],
                stubbedUploadTransferResult: .success(
                    MockTransfer(nodeHandle: defaultNode.handle, parentHandle: defaultParentNode.handle)
                )
            )
            
            let transfer = try await sut.uploadFile(
                at: testFileURL,
                to: defaultParentNode.toNodeEntity(),
                startHandler: nil,
                progressHandler: nil
            )
            
            #expect(transfer.nodeHandle == defaultNode.handle)
            #expect(transfer.parentHandle == defaultParentNode.handle)
        }
        
        @Test("Upload fails with error")
        func shouldThrowError() async throws {
            let sut = makeSUT(
                nodes: [defaultParentNode],
                stubbedUploadTransferResult: .failure(MockError(errorType: .apiEFailed))
            )
            
            await #expect(performing: {
                try await sut.uploadFile(
                    at: testFileURL,
                    to: defaultParentNode.toNodeEntity(),
                    startHandler: nil,
                    progressHandler: nil
                )
            }, throws: { error in
                if let errorEntity = error as? TransferErrorEntity, errorEntity == .upload {
                    true
                } else {
                    false
                }
            })
        }
        
        @Test("Could not find node by handle")
        func shouldThrowCouldNotFindNodeByHandleError() async throws {
            let sut = makeSUT(nodes: [])
            
            await #expect(throws: TransferErrorEntity.couldNotFindNodeByHandle, performing: {
                try await sut.uploadFile(
                    at: testFileURL,
                    to: defaultParentNode.toNodeEntity(),
                    startHandler: nil,
                    progressHandler: nil
                )
            })
        }
    }
}
