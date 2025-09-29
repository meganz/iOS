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
    
    @Test("Fetch Nodes Request Start Updates")
    func shouldYieldFetchNodesRequestStartUpdates() async {
        let requestEntities = [
            RequestEntity(nodeHandle: 1, type: .fetchNodes),
            RequestEntity(nodeHandle: 2, type: .login),
            RequestEntity(nodeHandle: 3, type: .fetchNodes)
        ]
        
        let requestStatesRepository = MockRequestStatesRepository(folderLinkRequestStartUpdates: requestEntities.async.eraseToAnyAsyncSequence())
        let sut = makeSUT(requestStatesRepository: requestStatesRepository)
        
        var handles: [HandleEntity] = []
        for await request in sut.fetchNodesRequestStartUpdates {
            handles.append(request.nodeHandle)
        }
        
        #expect(handles == [1, 3])
    }
    
    @Suite("Request finish updates tests")
    struct RequestFinishUpdatesTests {
        @Test func shouldYieldRequestEntityWhenSuccess() async {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(nodeHandle: 1, type: .login),
                error: ErrorEntity(type: .ok)
            )
            
            let requestStatesRepository = MockRequestStatesRepository(folderLinkRequestFinishUpdates: [response].async.eraseToAnyAsyncSequence())
            
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            
            var results: [Result<RequestEntity, FolderLinkErrorEntity>] = []
            for await result in sut.requestFinishUpdates {
                results.append(result)
            }
            
            #expect(results.compactMap { try? $0.get().nodeHandle } == [1])
        }
        
        @Test(
            "Error has extra info",
            arguments: zip(
                [
                    ErrorEntity(type: .tryAgain, hasExtraInfo: true, linkError: .downETD),
                    ErrorEntity(type: .tryAgain, hasExtraInfo: true, userError: .etdSuspension),
                    ErrorEntity(type: .tryAgain, hasExtraInfo: true, userError: .copyrightSuspension),
                    ErrorEntity(type: .tryAgain, hasExtraInfo: true, linkError: .unknown, userError: .unknown),
                ],
                [
                    FolderLinkErrorEntity.linkUnavailable(.downETD),
                    .linkUnavailable(.userETDSuspension),
                    .linkUnavailable(.copyrightSuspension),
                    .linkUnavailable(.generic)
                ]
            )
        )
        func shouldYieldFolderLinkErrorEntityWhenErrorHasExtraInfo(errorEntity: ErrorEntity, expectedError: FolderLinkErrorEntity) async {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(type: .login),
                error: errorEntity
            )
            
            #expect(await requestFinishUpdatesShouldYieldCorrectError(response: response, expectedError: expectedError))
        }
        
        @Test(
            "Bad arguments error",
            arguments: zip(
                [
                    RequestTypeEntity.login,
                    RequestTypeEntity.fetchNodes,
                    RequestTypeEntity.getAttrFile,
                    RequestTypeEntity.logout
                ],
                [
                    FolderLinkErrorEntity.invalidDecryptionKey,
                    .linkUnavailable(.generic),
                    nil,
                    nil
                ]
            )
        )
        func shouldYieldFolderLinkErrorEntityForBadArgumentsError(requestType: RequestTypeEntity, expectedError: FolderLinkErrorEntity?) async {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(type: requestType),
                error: ErrorEntity(type: .badArguments)
            )
            
            #expect(await requestFinishUpdatesShouldYieldCorrectError(response: response, expectedError: expectedError))
        }
        
        @Test(
            "Resource not exists error",
            arguments: zip(
                [
                    RequestTypeEntity.login,
                    RequestTypeEntity.fetchNodes,
                    RequestTypeEntity.getAttrFile,
                    RequestTypeEntity.logout
                ],
                [
                    FolderLinkErrorEntity.linkUnavailable(.generic),
                    .linkUnavailable(.generic),
                    nil,
                    nil
                ]
            )
        )
        func shouldYieldFolderLinkErrorEntityForResourceNotExistsError(requestType: RequestTypeEntity, expectedError: FolderLinkErrorEntity?) async {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(type: requestType),
                error: ErrorEntity(type: .resourceNotExists)
            )
            
            #expect(await requestFinishUpdatesShouldYieldCorrectError(response: response, expectedError: expectedError))
        }
        
        @Test(
            "Resource expired error",
            arguments: zip(
                [
                    RequestTypeEntity.login,
                    RequestTypeEntity.fetchNodes,
                    RequestTypeEntity.getAttrFile,
                    RequestTypeEntity.logout
                ],
                [
                    FolderLinkErrorEntity.linkUnavailable(.expired),
                    .linkUnavailable(.expired),
                    .linkUnavailable(.expired),
                    .linkUnavailable(.expired)
                ]
            )
        )
        func shouldYieldFolderLinkErrorEntityForResourceExpiredError(requestType: RequestTypeEntity, expectedError: FolderLinkErrorEntity?) async {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(type: requestType),
                error: ErrorEntity(type: .resourceExpired)
            )
            
            #expect(await requestFinishUpdatesShouldYieldCorrectError(response: response, expectedError: expectedError))
        }
        
        @Test(
            "Incomplete request error",
            arguments: zip(
                [
                    RequestTypeEntity.login,
                    RequestTypeEntity.fetchNodes,
                    RequestTypeEntity.getAttrFile,
                    RequestTypeEntity.logout
                ],
                [
                    FolderLinkErrorEntity.decryptionKeyRequired,
                    .decryptionKeyRequired,
                    .decryptionKeyRequired,
                    .decryptionKeyRequired
                ]
            )
        )
        func shouldYieldFolderLinkErrorEntityForIncompleteRequestError(requestType: RequestTypeEntity, expectedError: FolderLinkErrorEntity?) async {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(type: requestType),
                error: ErrorEntity(type: .incompleteRequest)
            )
            
            #expect(await requestFinishUpdatesShouldYieldCorrectError(response: response, expectedError: expectedError))
        }
        
        @Test(
            "Other errors",
            arguments: zip(
                [
                    RequestTypeEntity.login,
                    RequestTypeEntity.fetchNodes,
                    RequestTypeEntity.getAttrFile,
                    RequestTypeEntity.logout
                ],
                [
                    FolderLinkErrorEntity.linkUnavailable(.generic),
                    .fetchNodesFailed,
                    nil,
                    nil
                ]
            )
        )
        func shouldYieldFolderLinkErrorEntityForOtherErrors(requestType: RequestTypeEntity, expectedError: FolderLinkErrorEntity?) async throws {
            let response = RequestResponseEntity(
                requestEntity: RequestEntity(type: requestType),
                error: ErrorEntity(type: .tryAgain)
            )
            
            #expect(await requestFinishUpdatesShouldYieldCorrectError(response: response, expectedError: expectedError))
        }
        
        private func requestFinishUpdatesShouldYieldCorrectError(response: RequestResponseEntity, expectedError: FolderLinkErrorEntity?) async -> Bool {
            let requestStatesRepository = MockRequestStatesRepository(folderLinkRequestFinishUpdates: [response].async.eraseToAnyAsyncSequence())
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            
            var iterator = sut.requestFinishUpdates.makeAsyncIterator()
            
            var receivedError: FolderLinkErrorEntity?
            do {
                _ = try await iterator.next()?.get()
            } catch {
                receivedError = error
            }
            
            return receivedError == expectedError
        }
    }
}
