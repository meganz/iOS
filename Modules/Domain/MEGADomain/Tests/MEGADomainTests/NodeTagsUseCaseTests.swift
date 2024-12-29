import MEGADomain
import MEGADomainMock
import Testing

struct NodeTagsUseCaseTests {
    
    @Test("Verify searchTags result",
     arguments: [
        Optional<[String]>.none,
        ["t1"],
        ["t1, t2"],
        ["t1, t2", "t3"]
    ])
    func testSearchTags(searchResults: [String]?) async {
        let (sut, repo) = makeSUTAndDependencies()
        repo._searchTags = searchResults
        var results: [String]?
        results = await sut.searchTags(for: nil)
        #expect(results == searchResults)
    }

    @Test("Verify getTags result",
     arguments: [
        Optional<[String]>.none,
        ["t1"],
        ["t1, t2"],
        ["t1, t2", "t3"]
    ])
    func testSearchTags(getTagsResult: [String]?) async {
        let (sut, repo) = makeSUTAndDependencies()
        repo._searchTags = getTagsResult
        var results: [String]?
        results = await sut.searchTags(for: nil)
        #expect(results == getTagsResult)
    }

    private func makeSUTAndDependencies() -> (NodeTagsUseCase, MockNodeTagsRepository) {
        let mockNodeTagsRepo = MockNodeTagsRepository.newRepo
        return (NodeTagsUseCase(repository: mockNodeTagsRepo), mockNodeTagsRepo)
    }
}
