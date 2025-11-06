@testable import CloudDrive
import Testing

@Suite("NodeTagsViewModel Tests")
struct NodeTagsViewModelTests {

    @MainActor
    @Test("verify setting the isSelectionEnabled property")
    func verifyIsSelectionEnabled() {
        let viewModel1 = NodeTagsViewModel(isSelectionEnabled: true)
        #expect(viewModel1.isSelectionEnabled)
        let viewModel2 = NodeTagsViewModel(isSelectionEnabled: false)
        #expect(!viewModel2.isSelectionEnabled)
    }

    @MainActor
    @Test("Test the insertion of a tag at the start")
    func testInsertionOfATagAtTheStart() {
        let tags = ["#tag1", "#tag2", "#tag3"]
        let tagViewModels = tags.map { NodeTagViewModel(tag: $0, isSelected: false)}
        let viewModel = NodeTagsViewModel(tagViewModels: tagViewModels, isSelectionEnabled: true)
        viewModel.prepend(tagViewModel: NodeTagViewModel(tag: "#tag4", isSelected: false))
        #expect(viewModel.tagViewModels.first?.tag == "#tag4")
    }

    @MainActor
    @Test("Test the updating of tags when tags are reordered by selection", arguments: [0, 1, 2])
    func verifyUpdateTagsReorderedBySelection(selectedIndex: Int) {
        let tags = ["#tag1", "#tag2", "#tag3"]
        var tagViewModels = tags.map { NodeTagViewModel(tag: $0, isSelected: false)}
        let viewModel = NodeTagsViewModel(tagViewModels: tagViewModels, isSelectionEnabled: true)
        tagViewModels[selectedIndex] = NodeTagViewModel(tag: tags[selectedIndex], isSelected: true)
        viewModel.updateTagsReorderedBySelection(tagViewModels)
        let expectedTags = [tags[selectedIndex]] + tags
            .enumerated()
            .compactMap { $0 == selectedIndex ? nil : $1 }
        #expect(viewModel.tagViewModels.map(\.tag) == expectedTags)
        #expect(viewModel.tagViewModels.map(\.isSelected) == [true, false, false])
    }
}
