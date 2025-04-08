import MEGADomain
import MEGADomainMock
import Testing

@Suite("FolderLinkUseCase Tests")
struct FolderLinkUseCaseTests {
    func makeSUT(
        transferRepository: MockTransferRepository = MockTransferRepository(),
        nodeRepository: MockNodeRepository = MockNodeRepository()
    ) -> FolderLinkUseCase<MockTransferRepository, MockNodeRepository> {
        FolderLinkUseCase(transferRepository: transferRepository, nodeRepository: nodeRepository)
    }
    
    @Test("Completed download transfer")
    func shouldYieldCompletedDownloadTransferUpdates() async {
        let transferEntities = [
            TransferEntity(type: .upload, nodeHandle: 1),
            TransferEntity(type: .download, nodeHandle: 2, isStreamingTransfer: true),
            TransferEntity(type: .download, nodeHandle: 3, isStreamingTransfer: false)
        ]
        
        let transferRepository = MockTransferRepository(completedTransfers: transferEntities)
        let sut = makeSUT(transferRepository: transferRepository)
        
        var handles: [HandleEntity] = []
        for await handle in sut.completedDownloadTransferUpdates {
            handles.append(handle)
        }
        
        #expect(handles == [3])
    }
    
    @Test("Node Updates")
    func shouldYieldNodeUpdates() async {
        let nodeEntities = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
        ]
        
        let nodeRepository = MockNodeRepository(folderLinkNodeUpdates: [nodeEntities].async.eraseToAnyAsyncSequence())
        let sut = makeSUT(nodeRepository: nodeRepository)
        
        var handles: [[HandleEntity]] = []
        for await nodeEntities in sut.nodeUpdates {
            handles.append(nodeEntities.map(\.handle))
        }
        
        #expect(handles == [[1, 2]])
    }
}
