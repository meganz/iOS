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
}
