@testable import MEGA
import Testing

@Suite("ExistingTagsViewModel Tests")
struct ExistingTagsViewModelTests {
    @MainActor
    @Test(
        "Test if the view model contains the tags to display",
        arguments: [
            ([], false),
            (["tag1"], true)
        ]
    )
    func verifyContainsTags(tags: [String], result: Bool) {
        let tagViewModels = tags.map {
            NodeTagViewModel(tag: $0, isSelectionEnabled: false, isSelected: false)
        }
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: tagViewModels))
        #expect(sut.containsTags == result)
    }

    @MainActor
    @Test("Test if the view model contains the tags to display")
    func verifyAddAndSelectNewTag() {
        let tagViewModel = NodeTagViewModel(tag: "tag2", isSelectionEnabled: false, isSelected: false)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel]))
        sut.addAndSelectNewTag("tag1")
        #expect(sut.tagsViewModel.tagViewModels.first?.tag == "tag1")
    }

    @MainActor
    @Test("Test the search for tags in the account.")
    func verifySearchTags() async {
        let tags = ["tag1"]
        let searcher = MockNodeTagsSearcher(tags: tags)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: []), nodeTagSearcher: searcher)
        await sut.searchTags(for: nil)
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == tags)
        #expect(sut.isLoading == false)
    }

    // MARK: - Helpers

    private typealias SUT = ExistingTagsViewModel

    @MainActor
    private func makeSUT(
        tagsViewModel: NodeTagsViewModel,
        nodeTagSearcher: some NodeTagsSearching = MockNodeTagsSearcher(),
        isSelectionEnabled: Bool = false
    ) -> SUT {
        ExistingTagsViewModel(
            tagsViewModel: tagsViewModel,
            nodeTagSearcher: nodeTagSearcher,
            isSelectionEnabled: isSelectionEnabled
        )
    }
}
