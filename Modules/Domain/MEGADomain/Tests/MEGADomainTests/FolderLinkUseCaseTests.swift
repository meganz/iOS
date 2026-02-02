import MEGADomain
import MEGADomainMock
import Testing

func makeSUT(
    transferRepository: MockTransferRepository = MockTransferRepository(),
    nodeRepository: MockNodeRepository = MockNodeRepository(),
    requestStatesRepository: MockRequestStatesRepository = MockRequestStatesRepository()
) -> FolderLinkUseCase<MockTransferRepository, MockNodeRepository, MockRequestStatesRepository> {
    FolderLinkUseCase(transferRepository: transferRepository, nodeRepository: nodeRepository, requestStatesRepository: requestStatesRepository)
}

@Suite("FolderLinkUseCase Tests")
struct FolderLinkUseCaseTests {
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
    
    @Test("File Attribute Updates")
    func shouldYieldSuccessFileAttributeUpdatesOnly() async {
        let getFileAttributeSuccessRequest = RequestResponseEntity(
            requestEntity: RequestEntity(nodeHandle: 1, type: .getAttrFile),
            error: ErrorEntity(type: .ok)
        )
        
        let getFileAttributeFailureRequest = RequestResponseEntity(
            requestEntity: RequestEntity(nodeHandle: 2, type: .getAttrFile),
            error: ErrorEntity(type: .badArguments)
        )
        
        let loginRequest = RequestResponseEntity(
            requestEntity: RequestEntity(nodeHandle: 3, type: .login),
            error: ErrorEntity(type: .ok)
        )
        
        let requestStatesRepository = MockRequestStatesRepository(
            folderLinkRequestFinishUpdates: [
                getFileAttributeSuccessRequest,
                getFileAttributeFailureRequest,
                loginRequest
            ].async.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(requestStatesRepository: requestStatesRepository)
        
        var results: [HandleEntity] = []
        for await result in sut.fileAttributesUpdates {
            results.append(result)
        }
        
        #expect(results == [1])
    }
    
}
