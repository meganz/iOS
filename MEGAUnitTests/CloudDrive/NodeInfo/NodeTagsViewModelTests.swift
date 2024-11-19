@testable import MEGA
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
}
