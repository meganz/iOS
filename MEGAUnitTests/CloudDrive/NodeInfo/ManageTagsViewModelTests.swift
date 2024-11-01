import Combine
@testable import MEGA
import Testing

@Suite("ManageTagsViewModel Tests")
struct ManageTagsViewModelTests {
    
    @MainActor
    @Test(
        "Verify tagNameState updates based on tagName input",
        arguments: [
            ("", ManageTagsViewModel.TagNameState.empty),
            ("tag1", ManageTagsViewModel.TagNameState.valid),
            ("invalid@tag!", ManageTagsViewModel.TagNameState.invalid),
            (String(repeating: "a", count: 33), ManageTagsViewModel.TagNameState.tooLong)
        ]
    )
    func verifyTagNameState(tagName: String, expectedState: ManageTagsViewModel.TagNameState) async {
        let viewModel = makeSUT()
        viewModel.tagName = tagName

        await withCheckedContinuation { continuation in
            var resumed = false

            let cancellable = viewModel
                .$tagNameState
                .sink { newState in
                    if newState == expectedState && !resumed {
                        resumed = true
                        continuation.resume()
                    }
                }

            // timeout task
            Task {
                try await Task.sleep(nanoseconds: 500_000_000)
                if !resumed {
                    resumed = true
                    continuation.resume()
                }
                cancellable.cancel()
            }
        }

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
        initialTagName: String,
        expectedContainsTag: Bool,
        expectedTagName: String,
        expectedContainsExistingTags: Bool
    ) {
        let viewModel = makeSUT()

        // Set the initial tag name and add it
        viewModel.tagName = initialTagName
        viewModel.addTag()

        // Expectation checks
        #expect(viewModel.existingTagsViewModel.tags.contains(initialTagName) == expectedContainsTag)
        #expect(viewModel.tagName == expectedTagName)
        #expect(viewModel.containsExistingTags == expectedContainsExistingTags)
    }

    @MainActor
    private func makeSUT() -> ManageTagsViewModel {
        ManageTagsViewModel(
            navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
            existingTagsViewModel: ExistingTagsViewModel()
        )
    }
}
