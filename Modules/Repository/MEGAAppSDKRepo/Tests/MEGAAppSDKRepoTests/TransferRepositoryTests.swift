import Foundation
@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("TransferRepository Tests")
struct TransferRepositoryTests {
    
    @Suite("Download node")
    struct DownloadNodeTests {
        @Test("Download success")
        func shouldReturnTransfer() async throws {
            let node = MockNode(handle: 1)
            let sdk = MockSdk(nodes: [node])
            sdk.stubbedDownloadTransferResult = .success(MockTransfer(nodeHandle: node.handle))
            
            let sut = TransferRepository(sdk: sdk)
            
            let transfer = try await sut.download(
                node: node.toNodeEntity(),
                to: URL(fileURLWithPath: "/path"),
                startHandler: nil,
                progressHandler: nil
            )
            
            #expect(transfer.nodeHandle == node.handle)
        }
        
        @Test("Download fails with error")
        func shouldThrowError() async throws {
            let node = MockNode(handle: 1)
            let sdk = MockSdk(nodes: [node])
            sdk.stubbedDownloadTransferResult = .failure(MockError(errorType: .apiEFailed))
            
            let sut = TransferRepository(sdk: sdk)
            
            await #expect(performing: {
                try await sut.download(
                    node: node.toNodeEntity(),
                    to: URL(fileURLWithPath: "/path"),
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
            let node = MockNode(handle: 1)
            let sdk = MockSdk(nodes: [])
            let sut = TransferRepository(sdk: sdk)
            
            await #expect(throws: TransferErrorEntity.couldNotFindNodeByHandle, performing: {
                try await sut.download(
                    node: node.toNodeEntity(),
                    to: URL(fileURLWithPath: "/path"),
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
            let node = MockNode(handle: 1)
            let parentNode = MockNode(handle: 2)
            let sdk = MockSdk(nodes: [parentNode])
            sdk.stubbedUploadTransferResult = .success(MockTransfer(nodeHandle: node.handle, parentHandle: parentNode.handle))
            
            let sut = TransferRepository(sdk: sdk)
            
            let transfer = try await sut.uploadFile(
                at: URL(fileURLWithPath: "/path"),
                to: parentNode.toNodeEntity(),
                startHandler: nil,
                progressHandler: nil
            )
            
            #expect(transfer.nodeHandle == node.handle)
            #expect(transfer.parentHandle == parentNode.handle)
        }
        
        @Test("Upload fails with error")
        func shouldThrowError() async throws {
            let parentNode = MockNode(handle: 2)
            let sdk = MockSdk(nodes: [parentNode])
            sdk.stubbedUploadTransferResult = .failure(MockError(errorType: .apiEFailed))
            
            let sut = TransferRepository(sdk: sdk)
            
            await #expect(performing: {
                try await sut.uploadFile(
                    at: URL(fileURLWithPath: "/path"),
                    to: parentNode.toNodeEntity(),
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
            let parentNode = MockNode(handle: 2)
            let sdk = MockSdk(nodes: [])
            let sut = TransferRepository(sdk: sdk)
            
            await #expect(throws: TransferErrorEntity.couldNotFindNodeByHandle, performing: {
                try await sut.uploadFile(
                    at: URL(fileURLWithPath: "/path"),
                    to: parentNode.toNodeEntity(),
                    startHandler: nil,
                    progressHandler: nil
                )
            })
        }
    }
}
