@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("TransferInventoryUseCaseHelper Tests")
struct TransferInventoryUseCaseHelperTests {
    private static func makeSUT(
        transfers: [TransferEntity] = [],
        completed: [TransferEntity] = []
    ) -> TransferInventoryUseCaseHelper {
        let inventory = MockTransferInventoryUseCase(
            transfers: transfers,
            completedTransfers: completed
        )
        let fs = MockFileSystemRepository()
        let store = MockMEGAStore(
            fetchOfflineNodes: nil,
            offlineNode: nil
        )
        return TransferInventoryUseCaseHelper(
            transferInventoryUseCase: inventory,
            fileSystem: fs,
            store: store
        )
    }
    
    private static func areTransferEntitiesEqual(
        _ lhs: [TransferEntity],
        _ rhs: [TransferEntity]
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { a, b in
            a.nodeHandle == b.nodeHandle &&
            a.type       == b.type       &&
            a.path       == b.path       &&
            a.appData    == b.appData
        }
    }
    
    @Suite("Sync transfers")
    struct SyncTransfers {
        @Test("forwards the flag and returns exactly what the use-case gives")
        func forwardsFlag() {
            let expected = [
                TransferEntity(type: .download, path: nil, nodeHandle: 1, publicNode: nil, appData: nil)
            ]
            let sut = makeSUT(transfers: expected)
            
            let actual = sut.transfers()
            
            #expect(areTransferEntitiesEqual(actual, expected))
        }
    }
    
    @Suite("Async transfers")
    struct AsyncTransfers {
        @Test("forwards the flag and returns exactly what the use-case gives")
        @MainActor
        func forwardsFlagAsync() async {
            let expected = [
                TransferEntity(type: .download, path: nil, nodeHandle: 2, publicNode: nil, appData: nil)
            ]
            let sut = makeSUT(transfers: expected)
            
            let actual = await sut.transfers()
            
            #expect(areTransferEntitiesEqual(actual, expected))
        }
    }
    
    @Suite("completedTransfers filtering")
    struct CompletedTransfers {
        @Test("forwards the filteringUserTransfers flag")
        func forwardsFilteringFlag() {
            let expected = TransferEntity(type: .download, path: nil, nodeHandle: 99, publicNode: nil, appData: nil)
            let sut = makeSUT(completed: [expected])
            
            let resultTrue  = sut.completedTransfers(filteringUserTransfers: true)
            let resultFalse = sut.completedTransfers(filteringUserTransfers: false)
            
            #expect(areTransferEntitiesEqual(resultTrue, [expected]))
            #expect(areTransferEntitiesEqual(resultFalse, [expected]))
        }
    }
    
    @Suite("documentsDirectory forwarding")
    struct DocumentsDirectory {
        @Test("forwards to the inventory use-case")
        func forwards() {
            let customPath = "/custom/docs"
            let mockInv = MockTransferInventoryUseCase(defaultDocumentsDirectory: customPath)
            let sut = TransferInventoryUseCaseHelper(
                transferInventoryUseCase: mockInv,
                fileSystem: MockFileSystemRepository(),
                store: MockMEGAStore()
            )
            
            let actual = sut.documentsDirectory()
            #expect(actual.path == customPath)
        }
    }
}
