@testable import CloudDrive
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
        let tags = ["tag1", "tag2", "tag3", "tag4"]
        let searcher = MockNodeTagsSearcher(tags: tags)
        let selectedTags = [
            NodeTagViewModel(tag: "tag2", isSelectionEnabled: true, isSelected: true),
            NodeTagViewModel(tag: "tag3", isSelectionEnabled: true, isSelected: true)
        ]
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: selectedTags), nodeTagSearcher: searcher)
        await sut.searchTags(for: nil)
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2", "tag3", "tag1", "tag4"])
        #expect(sut.isLoading == false)
    }

    @MainActor
    @Test("Test adding the tags and then searching for tags in the account.")
    func verifyAddAndSearchTags() async {
        let tags = ["tag1", "tag2", "tag3", "tag4"]
        let searcher = MockNodeTagsSearcher(tags: tags)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: []), nodeTagSearcher: searcher)
        let newTagName = "zero"
        sut.addAndSelectNewTag(newTagName)
        await sut.searchTags(for: "ta")
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == tags)
        await sut.searchTags(for: nil)
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == [newTagName] + tags)
        #expect(sut.isLoading == false)
    }

    @MainActor
    @Test("Test searching for non selected tag and then searching for selected tag and see if the selection is preserved.")
    func verifySearchingOfSelectedTags() async {
        let tags = ["tag1", "tag2", "tag3", "tag4"]
        let searcher = MockNodeTagsSearcher(tags: tags)
        let selectedTagViewModel = NodeTagViewModel(tag: "tag2", isSelectionEnabled: true, isSelected: true)
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: [selectedTagViewModel]),
            nodeTagSearcher: searcher
        )
        await sut.searchTags(for: "tag3")
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag3"])
        await sut.searchTags(for: nil)
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2", "tag1", "tag3", "tag4"])
        #expect(sut.tagsViewModel.tagViewModels.first?.isSelected == true)
    }

    @MainActor
    @Test("Test adding tags with diacritics and then searching for tags with diacritics.")
    func verifyAddAndSearchTagsWithDiacritic() async {
        let tagViewModel = NodeTagViewModel(tag: "tag2", isSelectionEnabled: false, isSelected: false)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel]))
        sut.addAndSelectNewTag("holešovice")
        sut.addAndSelectNewTag("holesovice")
        await sut.searchTags(for: "sov")
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["holešovice", "holesovice"])
        await sut.searchTags(for: "šov")
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["holešovice", "holesovice"])
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
