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
    
    func testHide_onNodeHiddenSetSuccessfully_shouldReturnNodeWithAttribute() async throws {
        let expectedNode = NodeEntity(handle: 5, isMarkedSensitive: true)
        let repository = MockNodeActionRepository(setSensitiveResult: .success(expectedNode))
        
        let sut = NodeActionUseCase(repo: repository)
        
        let result = try await sut.hide(node: NodeEntity(handle: 5))
        XCTAssertEqual(result, expectedNode)
        XCTAssertTrue(repository.sensitive == true)
    }
    
    func testHide_onFailed_shouldThrowCorrectError() async {
        let repository = MockNodeActionRepository(setSensitiveResult: .failure(GenericErrorEntity()))
        
        let sut = NodeActionUseCase(repo: repository)
        
        do {
            _ = try await sut.hide(node: NodeEntity(handle: 5))
            XCTFail("Should have thrown exception")
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Incorrect exception")
        }
    }
    
    func testUnhide_onNodeUnhiddenSetSuccessfully_shouldReturnNodeWithAttribute() async throws {
        let expectedNode = NodeEntity(handle: 8, isMarkedSensitive: false)
        let repository = MockNodeActionRepository(setSensitiveResult: .success(expectedNode))
        
        let sut = NodeActionUseCase(repo: repository)
        
        let result = try await sut.unhide(node: NodeEntity(handle: 8))
        
        XCTAssertEqual(result, expectedNode)
        XCTAssertTrue(repository.sensitive == false)
    }
    
    func testUnhide_onFailed_shouldThrowCorrectError() async {
        let repository = MockNodeActionRepository(setSensitiveResult: .failure(NodeErrorEntity.nodeNotFound))
        
        let sut = NodeActionUseCase(repo: repository)
        
        do {
            _ = try await sut.unhide(node: NodeEntity(handle: 8))
            XCTFail("Should have thrown exception")
        } catch let error as NodeErrorEntity {
            XCTAssertEqual(error, .nodeNotFound)
        } catch {
            XCTFail("Incorrect exception")
        }
    }
}
