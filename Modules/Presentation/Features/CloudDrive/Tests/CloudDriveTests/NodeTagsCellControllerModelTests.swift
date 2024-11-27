@testable import CloudDrive
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellControllerModel Tests")
struct NodeTagsCellControllerModelTests {
    @MainActor
    @Test("Check for tags")
    func checkTags() {
        let tags = ["tag1", "tag2", "tag3"]
        let node = NodeEntity(tags: tags)
        let sut = makeSUT(node: node)
        #expect(sut.selectedTags == Set(tags))
        #expect(sut.cellViewModel.tags == tags)
    }

    @MainActor
    private func makeSUT(node: NodeEntity) -> NodeTagsCellControllerModel {
        NodeTagsCellControllerModel(node: node)
    }
}
