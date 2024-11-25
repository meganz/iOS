@testable import CloudDrive
import Testing

@Suite("NodeTagsViewModel Tests")
struct NodeTagsViewModelTests {

    @MainActor
    @Test("Test the update method")
    func updateTagsWidthModelWhenUpdateInvoked() {
        let tags = ["#tags1", "#tags2", "#tags3"]
        let tagViewModels = tags.map { NodeTagViewModel(tag: $0, isSelectionEnabled: false, isSelected: false)}
        let viewModel = NodeTagsViewModel(tagViewModels: tagViewModels)
        #expect(viewModel.tagsWidth.count == 0)
        viewModel.update("#noTag", with: 0)
        #expect(viewModel.tagsWidth.count == 0)
        viewModel.update("#tags2", with: 10)
        #expect(viewModel.tagsWidth.count == 1)
    }

    @MainActor
    @Test("Test the insertion of a tag at the start")
    func testInsertionOfATagAtTheStart() {
        let tags = ["#tag1", "#tag2", "#tag3"]
        let tagViewModels = tags.map { NodeTagViewModel(tag: $0, isSelectionEnabled: false, isSelected: false)}
        let viewModel = NodeTagsViewModel(tagViewModels: tagViewModels)
        viewModel.prepend(tagViewModel: NodeTagViewModel(tag: "#tag4", isSelectionEnabled: false, isSelected: false))
        #expect(viewModel.tagViewModels.first?.tag == "#tag4")
    }

    @MainActor
    @Test("Test the updating of tags when tags are reordered by selection", arguments: [0, 1, 2])
    func verifyUpdateTagsReorderedBySelection(selectedIndex: Int) {
        let tags = ["#tag1", "#tag2", "#tag3"]
        var tagViewModels = tags.map { NodeTagViewModel(tag: $0, isSelectionEnabled: true, isSelected: false)}
        let viewModel = NodeTagsViewModel(tagViewModels: tagViewModels)
        tagViewModels[selectedIndex] = NodeTagViewModel(
            tag: tags[selectedIndex],
            isSelectionEnabled: true,
            isSelected: true
        )
        viewModel.updateTagsReorderedBySelection(tagViewModels)
        let expectedTags = [tags[selectedIndex]] + tags
            .enumerated()
            .compactMap { $0 == selectedIndex ? nil : $1 }
        #expect(viewModel.tagViewModels.map(\.tag) == expectedTags)
        #expect(viewModel.tagViewModels.map(\.isSelectionEnabled) == (0..<3).map { _ in true })
        #expect(viewModel.tagViewModels.map(\.isSelected) == [true, false, false])
    }
}
