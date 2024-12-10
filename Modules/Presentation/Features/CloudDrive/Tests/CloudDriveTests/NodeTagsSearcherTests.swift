@testable import CloudDrive
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
        #expect(useCase.searchTexts == [nil])
        let updatedResult = await sut.searchTags(for: "tag1")
        #expect(updatedResult == ["tag1"])
        #expect(useCase.searchTexts == [nil])
        let finalResult = await sut.searchTags(for: nil)
        #expect(finalResult == tags)
        #expect(useCase.searchTexts == [nil])
    }

    @MainActor
    @Test("Verify the debounce")
    func verifyDebounce() async {
        let tags = ["tag1", "tag2", "tag3"]
        let useCase = MockNodeTagsUseCase(tags: tags)
        let sut = NodeTagsSearcher(nodeTagsUseCase: useCase)
        let task1 = Task {
            _ = await sut.searchTags(for: "tag1")
        }
        let task2 = Task(priority: .background) {
            _ = await sut.searchTags(for: "tag2")
        }
        _ = await [task1.value, task2.value]
        #expect(useCase.searchTexts == ["tag2"])
    }

    @MainActor
    @Test("Verify search when diacritics are present")
    func verifySearchForDiacritic() async {
        let tags = ["holesovice", "tag1", "tag2", "holešovice"]
        let useCase = MockNodeTagsUseCase(tags: tags)
        let sut = NodeTagsSearcher(nodeTagsUseCase: useCase)
        _ = await sut.searchTags(for: nil)
        var results = await sut.searchTags(for: "sovi")
        #expect(results == ["holesovice", "holešovice"])
        results = await sut.searchTags(for: "šovi")
        #expect(results == ["holesovice", "holešovice"])
    }
}
