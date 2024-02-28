import MEGADomain
import MEGADomainMock
import XCTest

final class NodeActionUseCaseTests: XCTestCase {
    func testCreateFolder() async throws {
        let name = "FolderName"
        let parent = NodeEntity(handle: 123)
        let createdFolder = NodeEntity(name: name, handle: 1, parentHandle: parent.handle)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(createdFolder))
        let sut = NodeActionUseCase(repo: nodeActionRepository)
    
        let nodeEntity = try await sut.createFolder(name: name, parent: parent)
        
        XCTAssertEqual(nodeEntity, createdFolder)
    }
    
    func testRenameNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let newName = "newName"
        let node = NodeEntity(name: "name")
        let nodeEntity = try await sut.rename(node: node, name: newName)
        XCTAssertEqual(nodeEntity.name, newName)
    }
    
    func testTrashNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let node = NodeEntity(parentHandle: 123)
        let nodeEntity = try await sut.trash(node: node)
        XCTAssertNotEqual(node.parentHandle, nodeEntity.parentHandle)
    }
    
    func testUntrashNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let node = NodeEntity(parentHandle: 123)
        let nodeEntity = try await sut.untrash(node: node)
        XCTAssertNotEqual(node.parentHandle, nodeEntity.parentHandle)
    }
    
    func testMoveNode() async throws {
        let sut = NodeActionUseCase(repo: MockNodeActionRepository.newRepo)
        let node = NodeEntity()
        let parent = NodeEntity()
        let nodeEntity = try await sut.move(node: node, toParent: parent)
        XCTAssertEqual(nodeEntity.parentHandle, parent.handle)
    }
    
    func testHide_onNodeSuccessAndFailed_shouldReturnBothResultTypesCorrectly() async throws {
        let firstNode = NodeEntity(handle: 5, isMarkedSensitive: true)
        let secondNode = NodeEntity(handle: 9, isMarkedSensitive: true)
        let repository = MockNodeActionRepository(
            setSensitiveResults: [firstNode.handle: .success(firstNode),
                                  secondNode.handle: .failure(GenericErrorEntity())])
        
        let sut = NodeActionUseCase(repo: repository)
        
        let results = await sut.hide(nodes: [firstNode, secondNode])
        
        XCTAssertEqual(results.count, 2)
        
        switch try XCTUnwrap(results[firstNode.handle]) {
        case .success(let node):
            XCTAssertEqual(node, firstNode)
        case .failure:
            XCTFail("Should have been successful")
        }
        
        switch try XCTUnwrap(results[secondNode.handle]) {
        case .success:
            XCTFail("Should have been failure")
        case .failure(let error):
            XCTAssertTrue(error is GenericErrorEntity)
        }
        
        XCTAssertTrue(repository.sensitive == true)
    }
    
    func testUnhide_onNodeSuccessAndFailed_shouldReturnBothResultTypesCorrectly() async throws {
        let firstNode = NodeEntity(handle: 8, isMarkedSensitive: false)
        let secondNode = NodeEntity(handle: 9, isMarkedSensitive: false)
        let expectedError = NodeErrorEntity.nodeNotFound
        let repository = MockNodeActionRepository(
            setSensitiveResults: [firstNode.handle: .success(firstNode),
                                  secondNode.handle: .failure(expectedError)])
        
        let sut = NodeActionUseCase(repo: repository)
        
        let results = await sut.unhide(nodes: [firstNode, secondNode])
        
        XCTAssertEqual(results.count, 2)
        
        switch try XCTUnwrap(results[firstNode.handle]) {
        case .success(let node):
            XCTAssertEqual(node, firstNode)
        case .failure:
            XCTFail("Should have been successful")
        }
        
        switch try XCTUnwrap(results[secondNode.handle]) {
        case .success:
            XCTFail("Should have been failure")
        case .failure(let error):
            XCTAssertEqual(error as? NodeErrorEntity, expectedError)
        }
        
        XCTAssertTrue(repository.sensitive == false)
    }
}
