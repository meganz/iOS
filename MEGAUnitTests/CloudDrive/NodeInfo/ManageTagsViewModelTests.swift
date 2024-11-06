import Combine
@testable import MEGA
import Testing

@Suite("ManageTagsViewModel Tests")
struct ManageTagsViewModelTests {
    
    @MainActor
    @Test(
        "Verify tagNameState updates based on tagName input",
        arguments: [
            ("", "", ManageTagsViewModel.TagNameState.empty),
            ("#", "", ManageTagsViewModel.TagNameState.empty),
            ("#test", "test", ManageTagsViewModel.TagNameState.valid),
            ("####test", "test", ManageTagsViewModel.TagNameState.valid),
            ("####test#", "test#", ManageTagsViewModel.TagNameState.invalid),
            ("####test#again", "test#again", ManageTagsViewModel.TagNameState.invalid),
            ("Tag1", "tag1", ManageTagsViewModel.TagNameState.valid),
            ("tag1", "", ManageTagsViewModel.TagNameState.valid),
            ("invalid@tag!", "", ManageTagsViewModel.TagNameState.invalid),
            (String(repeating: "a", count: 33), "", ManageTagsViewModel.TagNameState.tooLong)
        ]
    )
    func validateAndUpdateTagNameState(updatedTagName: String, expectedTagName: String, expectedState: ManageTagsViewModel.TagNameState) async {
        let viewModel = makeSUT()
        viewModel.tagName = ""
        viewModel.validateAndUpdateTagNameStateIfRequired(with: updatedTagName)
        #expect(viewModel.tagName == expectedTagName)
        #expect(viewModel.tagNameState == expectedState)
    }
    
    @MainActor
    @Test(
        "Verify addTag only adds valid tag names and clears tagName",
        arguments: [
            ("tag1", true, "", true),
            ("invalid@tag!", false, "invalid@tag!", false)
        ]
    )
    func verifyAddTag(
        updatedTagName: String,
        expectedContainsTag: Bool,
        expectedTagName: String,
        expectedContainsExistingTags: Bool
    ) {
        let viewModel = makeSUT()

        // Set the initial tag name and add it
        viewModel.tagName = updatedTagName
        viewModel.validateAndUpdateTagNameStateIfRequired(with: updatedTagName)
        viewModel.addTag()

        // Expectation checks
        #expect(viewModel.existingTagsViewModel.tags.contains(updatedTagName) == expectedContainsTag)
        #expect(viewModel.tagName == expectedTagName)
        #expect(viewModel.containsExistingTags == expectedContainsExistingTags)
    }

    @MainActor
    @Test("Verify clear text field")
    func verifyClearTextField() {
        let viewModel = makeSUT()

        let initialTagName = "Initial Tag Name"
        viewModel.tagName = initialTagName
        #expect(viewModel.tagName == initialTagName)
        viewModel.clearTextField()
        #expect(viewModel.tagName == "")
    }

    @MainActor
    private func makeSUT() -> ManageTagsViewModel {
        ManageTagsViewModel(
            navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
            existingTagsViewModel: ExistingTagsViewModel()
        )
    }
}
