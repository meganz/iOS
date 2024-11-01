@testable import MEGA
import Testing

@Suite("ExistingTagsViewModel Tests")
struct ExistingTagsViewModelTests {

    @MainActor
    @Test("Test the formattedTags variable")
    func verifyFormattedTags() {
        let tags = ["tag1", "tag2", "tag3"]
        let viewModel = ExistingTagsViewModel(tags: tags)
        #expect(viewModel.formattedTags == ["#tag1", "#tag2", "#tag3"])
    }

    @MainActor
    @Test(
        "Test the toggle method",
        arguments: [
            ("tag1", Set([]), Set(["tag1"])),
            ("tag1", Set(["tag1"]), Set([]))
        ]
    )
    func verifyToggle(selectedTag: String, selectedTags: Set<String>, expectedTags: Set<String>) {
        let tags = ["tag1", "tag2", "tag3"]
        let viewModel = ExistingTagsViewModel(tags: tags, selectedTags: selectedTags)
        viewModel.toggle(tag: selectedTag)
        #expect(viewModel.selectedTags == expectedTags)
    }

    @MainActor
    @Test("Test the toggle method")
    func verifyAddAndSelectNewTag() {
        let tags = ["tag1", "tag2", "tag3"]
        let viewModel = ExistingTagsViewModel(tags: tags)
        viewModel.addAndSelectNewTag("tag4")
        #expect(viewModel.tags == ["tag1", "tag2", "tag3", "tag4"])
        #expect(viewModel.selectedTags == ["tag4"])
    }

    @MainActor
    @Test("Test the toggle method")
    func verifyIsSelected() {
        let tags = ["tag1", "tag2", "tag3"]
        let viewModel = ExistingTagsViewModel(tags: tags, selectedTags: ["tag4"])
        #expect(viewModel.isSelected("#tag4"))
        #expect(viewModel.isSelected("tag4"))
    }
}
