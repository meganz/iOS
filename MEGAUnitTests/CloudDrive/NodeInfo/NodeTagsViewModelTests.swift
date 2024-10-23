@testable import MEGA
import Testing

@Suite("NodeTagsViewModel Tests")
struct NodeTagsViewModelTests {

    @MainActor
    @Test("Test the update method")
    func updateTagsWidthModelWhenUpdateInvoked() {
        let tags = ["#tags1", "#tags2", "#tags3"]
        let viewModel = NodeTagsViewModel(tags: tags)
        #expect(viewModel.tagsWidth.count == 0)
        viewModel.update("#noTag", with: 0)
        #expect(viewModel.tagsWidth.count == 0)
        viewModel.update("#tags2", with: 10)
        #expect(viewModel.tagsWidth.count == 1)
    }
}
