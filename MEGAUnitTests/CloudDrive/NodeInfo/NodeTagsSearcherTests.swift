@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsSearcherTests Tests")
struct NodeTagsSearcherTests {

    @MainActor
    @Test("Test to make sure the search tags function caches the all tags")
    func verifySearchTags() async {
        let tags = ["tag1", "tag2", "tag3"]
        let useCase = MockNodeTagsUseCase(tags: tags)
        let sut = NodeTagsSearcher(nodeTagsUseCase: useCase)
        let initialResult = await sut.searchTags(for: nil)
        #expect(initialResult == tags)
        #expect(useCase.numberOfCalls == 1)
        let updatedResult = await sut.searchTags(for: "tag1")
        #expect(updatedResult == ["tag1"])
        #expect(useCase.numberOfCalls == 1)
        let finalResult = await sut.searchTags(for: nil)
        #expect(finalResult == tags)
        #expect(useCase.numberOfCalls == 1)
    }
}
