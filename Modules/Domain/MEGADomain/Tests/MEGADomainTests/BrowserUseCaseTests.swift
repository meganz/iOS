import MEGADomain
import MEGADomainMock
import Testing

@Suite("BrowserUseCase Tests")
struct BrowserUseCaseTests {
    func makeSUT(
        requestStatesRepository: MockRequestStatesRepository = MockRequestStatesRepository(),
        nodeRepository: MockNodeRepository = MockNodeRepository()
    ) -> BrowserUseCase {
        BrowserUseCase(
            requestStatesRepository: requestStatesRepository,
            nodeRepository: nodeRepository
        )
    }
    
    @Test("Node Updates")
    func shouldYieldNodeUpdates() async {
        let expectedNodes = [
            NodeEntity(name: "Node1"),
            NodeEntity(name: "Node2")
        ]
        let nodeRepository = MockNodeRepository(
            nodeUpdates: [expectedNodes].async.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(nodeRepository: nodeRepository)
        
        var receivedNodes: [[NodeEntity]] = []
        for await nodes in sut.nodeUpdates {
            receivedNodes.append(nodes)
        }
        
        #expect(receivedNodes == [expectedNodes])
    }
    
    @Test("Copy Request Start Updates")
    func shouldYieldCopyRequestStartUpdates() async {
        let requestEntities = [
            RequestEntity(type: .copy),
            RequestEntity(type: .getAttrFile),
            RequestEntity(type: .copy)
        ]
        let requestStatesRepository = MockRequestStatesRepository(
            requestStartUpdates: requestEntities.async.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(requestStatesRepository: requestStatesRepository)
        
        var receivedUpdates = 0
        for await _ in sut.copyRequestStartUpdates {
            receivedUpdates += 1
        }
        
        #expect(receivedUpdates == 2)
    }
    
    @Test("Request Finish Updates")
    func shouldYieldFilteredRequestFinishUpdates() async {
        let requestEntities = [
            RequestResponseEntity(requestEntity: RequestEntity(nodeHandle: 1, type: .copy), error: ErrorEntity(type: .ok)),
            RequestResponseEntity(requestEntity: RequestEntity(nodeHandle: 2, type: .getAttrFile), error: ErrorEntity(type: .ok)),
            RequestResponseEntity(requestEntity: RequestEntity(nodeHandle: 3, type: .login), error: ErrorEntity(type: .ok))
        ]
        let requestStatesRepository = MockRequestStatesRepository(
            requestFinishUpdates: requestEntities.async.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(requestStatesRepository: requestStatesRepository)
        
        var receivedRequests: [RequestEntity] = []
        for await request in sut.requestFinishUpdates {
            receivedRequests.append(request)
        }
        
        #expect(receivedRequests.map(\.type) == [.copy, .getAttrFile])
    }
}
