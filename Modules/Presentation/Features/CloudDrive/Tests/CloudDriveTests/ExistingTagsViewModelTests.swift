@testable import CloudDrive
import MEGAL10n
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
            NodeTagViewModel(tag: $0, isSelected: false)
        }
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: tagViewModels, isSelectionEnabled: false))
        #expect(sut.containsTags == result)
    }

    @MainActor
    @Test("Test if the view model contains the tags to display")
    func verifyAddAndSelectNewTag() {
        let tagViewModel = NodeTagViewModel(tag: "tag2", isSelected: false)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel], isSelectionEnabled: false))
        sut.addAndSelectNewTag("tag1")
        #expect(sut.tagsViewModel.tagViewModels.first?.tag == "tag1")
    }

    @MainActor
    @Test("Test the search for tags in the account.")
    func verifySearchTags() async {
        let tags = ["tag1", "tag2", "tag3", "tag4"]
        let searcher = MockNodeTagsSearcher(tags: tags)
        let selectedTags = [
            NodeTagViewModel(tag: "tag2", isSelected: true),
            NodeTagViewModel(tag: "tag3", isSelected: true)
        ]
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: selectedTags, isSelectionEnabled: true),
            nodeTagSearcher: searcher
        )
        await sut.searchTags(for: nil)
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2", "tag3", "tag1", "tag4"])
        #expect(sut.isLoading == false)
    }

    @MainActor
    @Test("Test adding the tags and then searching for tags in the account.")
    func verifyAddAndSearchTags() async {
        let tags = ["tag1", "tag2", "tag3", "tag4"]
        let searcher = MockNodeTagsSearcher(tags: tags)
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: [], isSelectionEnabled: true),
            nodeTagSearcher: searcher
        )
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
        let selectedTagViewModel = NodeTagViewModel(tag: "tag2", isSelected: true)
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: [selectedTagViewModel], isSelectionEnabled: true),
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
        let tagViewModel = NodeTagViewModel(tag: "tag2", isSelected: false)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel], isSelectionEnabled: false))
        sut.addAndSelectNewTag("holešovice")
        sut.addAndSelectNewTag("holesovice")
        await sut.searchTags(for: "sov")
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["holesovice", "holešovice"])
        await sut.searchTags(for: "šov")
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["holesovice", "holešovice"])
    }

    @MainActor
    @Test("Test deselecting the newly added tag")
    func verifyDeselectingNewlyAddedTag() async {
        let tagViewModel = NodeTagViewModel(tag: "tag2", isSelected: false)
        let sut = makeSUT(tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel], isSelectionEnabled: true))
        sut.addAndSelectNewTag("tag1")
        sut.tagsViewModel.tagViewModels.first?.toggle()
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2"])
    }

    @MainActor
    @Test("Test selecting the existing Tag")
    func verifySelectingExistingTag() async {
        let tagViewModel1 = NodeTagViewModel(tag: "tag1", isSelected: false)
        let tagViewModel2 = NodeTagViewModel(tag: "tag2", isSelected: false)
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel1, tagViewModel2], isSelectionEnabled: true)
        )
        sut.tagsViewModel.tagViewModels.last?.toggle()
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2", "tag1"])
    }

    @MainActor
    @Test("Test deselecting the existing Tag")
    func verifyDeselectingExistingTag() async {
        let tagViewModel1 = NodeTagViewModel(tag: "tag1", isSelected: true)
        let tagViewModel2 = NodeTagViewModel(tag: "tag2", isSelected: true)
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: [tagViewModel1, tagViewModel2], isSelectionEnabled: true)
        )
        sut.tagsViewModel.tagViewModels.first?.toggle()
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2", "tag1"])
    }

    @MainActor
    @Test("Test selecting the NodeTagViewModel first and then deselecting it")
    func testSelectingTheNodeFirstAndDeselectingItLater() async {
        let tagViewModel1 = NodeTagViewModel(tag: "tag1", isSelected: false)
        let tagViewModel2 = NodeTagViewModel(tag: "tag2", isSelected: false)
        let tagViewModel3 = NodeTagViewModel(tag: "tag3", isSelected: false)

        let searcher = MockNodeTagsSearcher(tags: [])
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(
                tagViewModels: [tagViewModel1, tagViewModel2, tagViewModel3],
                isSelectionEnabled: true
            ),
            nodeTagSearcher: searcher
        )

        sut.tagsViewModel.tagViewModels.first(where: { $0.tag == "tag2" })?.toggle()
        sut.tagsViewModel.tagViewModels.first(where: { $0.tag == "tag3" })?.toggle()
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag2", "tag3", "tag1"])

        await searcher.update(tags: ["tag2"])
        await sut.searchTags(for: "tag2")
        sut.tagsViewModel.tagViewModels.first(where: { $0.tag == "tag2" })?.toggle()

        await searcher.update(tags: ["tag1", "tag2", "tag3"])
        await sut.searchTags(for: nil)
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag3", "tag1", "tag2"])
        sut.tagsViewModel.tagViewModels.first(where: { $0.tag == "tag3" })?.toggle()
        #expect(sut.tagsViewModel.tagViewModels.map(\.tag) == ["tag1", "tag2", "tag3"])
    }

    @MainActor
    @Test("Test node tags selection has reached max limit")
    func verifyHasReachedMaxLimit() {
        let selectedTags = [
            NodeTagViewModel(tag: "tag1", isSelected: true),
            NodeTagViewModel(tag: "tag2", isSelected: true),
            NodeTagViewModel(tag: "tag3", isSelected: true),
            NodeTagViewModel(tag: "tag4", isSelected: true),
            NodeTagViewModel(tag: "tag5", isSelected: true),
            NodeTagViewModel(tag: "tag6", isSelected: true),
            NodeTagViewModel(tag: "tag7", isSelected: true),
            NodeTagViewModel(tag: "tag8", isSelected: true),
            NodeTagViewModel(tag: "tag9", isSelected: true),
            NodeTagViewModel(tag: "tag10", isSelected: true)
        ]
        let sut = makeSUT(
            tagsViewModel: NodeTagsViewModel(tagViewModels: selectedTags, isSelectionEnabled: true)
        )

        let bannerMessage = Strings.Localizable.CloudDrive.NodeInfo.NodeTags.Selection.maxLimitReachedAlertMessage
        #expect(sut.hasReachedMaxLimit)
        #expect(sut.maxLimitReachedAlertMessage == bannerMessage)

        sut.tagsViewModel.tagViewModels.first?.toggle()
        #expect(sut.hasReachedMaxLimit == false)

        sut.tagsViewModel.tagViewModels.last?.toggle()
        #expect(sut.hasReachedMaxLimit)
        #expect(sut.maxLimitReachedAlertMessage == bannerMessage)
    }

    // MARK: - Helpers

    private typealias SUT = ExistingTagsViewModel

    @MainActor
    private func makeSUT(
        tagsViewModel: NodeTagsViewModel,
        nodeTagSearcher: some NodeTagsSearching = MockNodeTagsSearcher()
    ) -> SUT {
        ExistingTagsViewModel(
            tagsViewModel: tagsViewModel,
            nodeTagSearcher: nodeTagSearcher
        )
    }
}
