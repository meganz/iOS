import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeActionUseCase Tests")
struct NodeActionUseCaseTests {
    @Test
    func testCreateFolder() async throws {
        let name = "FolderName"
        let parent = NodeEntity(handle: 123)
        let createdFolder = NodeEntity(name: name, handle: 1, parentHandle: parent.handle)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(createdFolder))
        let sut = NodeActionUseCase(repo: nodeActionRepository)
    
        let nodeEntity = try await sut.createFolder(name: name, parent: parent)
        
        #expect(nodeEntity == createdFolder)
    }
    
    @Test
    func testRenameNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let newName = "newName"
        let node = NodeEntity(name: "name")
        let nodeEntity = try await sut.rename(node: node, name: newName)
        
        #expect(nodeEntity.name == newName)
    }
    
    @Test
    func testTrashNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let node = NodeEntity(parentHandle: 123)
        let nodeEntity = try await sut.trash(node: node)
        
        #expect(node.parentHandle != nodeEntity.parentHandle)
    }
    
    @Test
    func testUntrashNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let node = NodeEntity(parentHandle: 123)
        let nodeEntity = try await sut.untrash(node: node)
        
        #expect(node.parentHandle != nodeEntity.parentHandle)
    }
    
    @Test
    func testMoveNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let node = NodeEntity()
        let parent = NodeEntity()
        let nodeEntity = try await sut.move(node: node, toParent: parent)
        
        #expect(nodeEntity.parentHandle == parent.handle)
    }
    
    @Test
    func testHide_onNodeSuccessAndFailed_shouldReturnBothResultTypesCorrectly() async throws {
        let firstNode = NodeEntity(handle: 5, isMarkedSensitive: false)
        let secondNode = NodeEntity(handle: 9, isMarkedSensitive: false)
        let repository = MockNodeActionRepository(
            setSensitiveResults: [firstNode.handle: .success(firstNode),
                                  secondNode.handle: .failure(GenericErrorEntity())])
        
        let sut = NodeActionUseCase(repo: repository)
        
        let results = await sut.hide(nodes: [firstNode, secondNode])
        
        #expect(results.count == 2)
        
        switch try #require(results[firstNode.handle]) {
        case .success(let node):
            #expect(node == firstNode)
        case .failure:
            Issue.record("Should have been successful")
        }
        
        switch try #require(results[secondNode.handle]) {
        case .success:
            Issue.record("Should have been failure")
        case .failure(let error):
            #expect(error is GenericErrorEntity)
        }
        
        #expect(repository.sensitive == true)
    }
    
    @Test
    func testUnhide_onNodeSuccessAndFailed_shouldReturnBothResultTypesCorrectly() async throws {
        let firstNode = NodeEntity(handle: 8, isMarkedSensitive: true)
        let secondNode = NodeEntity(handle: 9, isMarkedSensitive: true)
        let expectedError = NodeErrorEntity.nodeNotFound
        let repository = MockNodeActionRepository(
            setSensitiveResults: [firstNode.handle: .success(firstNode),
                                  secondNode.handle: .failure(expectedError)])
        
        let sut = NodeActionUseCase(
            repo: repository,
            maxSetSensitivityTasks: 1)
        
        let results = await sut.unhide(nodes: [firstNode, secondNode])
        
        #expect(results.count == 2)
        
        switch try #require(results[firstNode.handle]) {
        case .success(let node):
            #expect(node == firstNode)
        case .failure:
            Issue.record("Should have been successful")
        }
        
        switch try #require(results[secondNode.handle]) {
        case .success:
            Issue.record("Should have been failure")
        case .failure(let error):
            #expect(error as? NodeErrorEntity == expectedError)
        }
        
        #expect(repository.sensitive == false)
    }
}
