
import XCTest
import MEGADomain
import MEGADomainMock

final class NodeAttributeUseCaseTests: XCTestCase {
    
    func testPathForNode() {
        let path = "/test/path"
        let repo = MockNodeAttributeRepository(path: path)
        let sut = NodeAttributeUseCase(repo: repo)
        let node = NodeEntity(handle: 1)
        XCTAssertEqual(path, sut.pathFor(node: node))
    }
    
    func testNumberChildrenForNode() {
        let children = 5
        let repo = MockNodeAttributeRepository(children: children)
        let sut = NodeAttributeUseCase(repo: repo)
        let node = NodeEntity(handle: 1)
        XCTAssertEqual(children, sut.numberChildrenFor(node: node))
    }
    
    func testIsInRubbishBin_shouldReturnTrue() {
        let repo = MockNodeAttributeRepository(isInRubbishBin: true)
        let sut = NodeAttributeUseCase(repo: repo)
        let node = NodeEntity(handle: 1)
        XCTAssertTrue(sut.isInRubbishBin(node: node))
    }
    
    func testIsInRubbishBin_shouldReturnFalse() {
        let sut = NodeAttributeUseCase(repo: MockNodeAttributeRepository.newRepo)
        let node = NodeEntity(handle: 1)
        XCTAssertFalse(sut.isInRubbishBin(node: node))
    }
}
