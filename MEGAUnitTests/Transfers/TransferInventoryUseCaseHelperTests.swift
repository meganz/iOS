@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("TransferInventoryUseCaseHelper Tests")
struct TransferInventoryUseCaseHelperTests {
    private static func makeSUT(
        transfers: [TransferEntity] = [],
        completed: [TransferEntity] = [],
        queuedUploads: [TransferRecordDTO]? = nil,
        nodeMappings: [HandleEntity: NodeEntity] = [:]
    ) -> TransferInventoryUseCaseHelper {
        let inventory = MockTransferInventoryUseCase(
            transfers: transfers,
            completedTransfers: completed
        )
        let nodeUseCase = MockNodeUseCase(nodes: nodeMappings)
        let fs = MockFileSystemRepository()
        let store = MockMEGAStore(
            fetchOfflineNodes: nil,
            offlineNode: nil,
            uploads: queuedUploads
        )
        return TransferInventoryUseCaseHelper(
            transferInventoryUseCase: inventory,
            nodeUseCase: nodeUseCase,
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
        @Test("filters to uploads whose node is a file")
        func filtersByTypeAndNode() {
            let fileNode = NodeEntity(handle: 10, isFile: true)
            let nonFileNode = NodeEntity(handle: 20, isFile: false)
            
            let keep = TransferEntity(type: .upload, path: nil, nodeHandle: 10, publicNode: nil, appData: nil)
            let drop1 = TransferEntity(type: .upload, path: nil, nodeHandle: 20, publicNode: nil, appData: nil)
            let drop2 = TransferEntity(type: .download, path: nil, nodeHandle: 30, publicNode: nil, appData: nil)
            
            let sut = makeSUT(
                completed: [keep, drop1, drop2],
                nodeMappings: [10: fileNode, 20: nonFileNode]
            )
            
            let actual = sut.completedTransfers()
            
            #expect(areTransferEntitiesEqual(actual, [keep]))
        }
        
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
    
    @Suite("queuedUploadTransfers mapping")
    struct QueuedUploads {
        @Suite("queuedUploadTransfers mapping")
        struct QueuedUploads {
            @Test("returns all non-nil localIdentifiers")
            func mapsLocalIdentifiers() {
                let dtoOne = TransferRecordDTO(localIdentifier: "one", parentNodeHandle: 0)
                let dtoTwo = TransferRecordDTO(localIdentifier: "two", parentNodeHandle: 0)
                
                let sut = makeSUT(queuedUploads: [dtoOne, dtoTwo])
                #expect(sut.queuedUploadTransfers() == ["one", "two"])
            }
            
            @Test("returns empty when store returns nil")
            func emptyWhenNil() {
                let sut = makeSUT(queuedUploads: nil)
                #expect(sut.queuedUploadTransfers().isEmpty)
            }
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
                nodeUseCase: MockNodeUseCase(),
                fileSystem: MockFileSystemRepository(),
                store: MockMEGAStore()
            )
            
            let actual = sut.documentsDirectory()
            #expect(actual.path == customPath)
        }
    }
    
    @Suite("removeAllUploadTransfers effect")
    struct RemoveAll {
        @Test("invokes the store to remove all upload transfers")
        func callsStore() {
            let store = MockMEGAStore(uploads: [])
            let sut = TransferInventoryUseCaseHelper(
                transferInventoryUseCase: MockTransferInventoryUseCase(),
                nodeUseCase: MockNodeUseCase(),
                fileSystem: MockFileSystemRepository(),
                store: store
            )
            
            sut.removeAllUploadTransfers()
            #expect(store.removeAllUploadTransfers_calledTimes == 1)
        }
    }
}
