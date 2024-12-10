@testable import CloudDrive
import Combine
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
        viewModel.onTagNameChanged(with: updatedTagName)
        #expect(viewModel.tagName == expectedTagName)
        #expect(viewModel.tagNameState == expectedState)
    }
    
    @MainActor
    @Test(
        "Verify addTag only adds valid tag names and clears tagName",
        arguments: [
            ("tag1", true, false, ""),
            ("invalid@tag!", false, false, "invalid@tag!")
        ]
    )
    func verifyAddTag(
        updatedTagName: String,
        containsTag: Bool,
        canAddNewTag: Bool,
        resultingTagName: String
    ) {
        let viewModel = makeSUT()

        // Set the initial tag name and add it
        viewModel.tagName = updatedTagName
        viewModel.onTagNameChanged(with: updatedTagName)
        viewModel.addTag()

        // Expectation checks
        #expect(viewModel.existingTagsViewModel.containsTags == containsTag)
        #expect(viewModel.containsExistingTags == containsTag)
        #expect(viewModel.canAddNewTag == canAddNewTag)
        #expect(viewModel.tagName == resultingTagName)
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
    @Test(
        "Verify loading all the tags from the account",
        arguments: [
            ([], false),
            (["tag1"], true)
        ]
    )
    func verifyLoadAllTags(tags: [String], containsExistingTags: Bool) async {
        let sut = makeSUT(nodeSearcher: MockNodeTagsSearcher(tags: tags))
        #expect(sut.containsExistingTags == false)
        await sut.loadAllTags()
        #expect(sut.containsExistingTags == containsExistingTags)
    }

    @MainActor
    @Test(
        "Verify the canAddNewTag property based on the results returned by the search API call",
        arguments: [
            (nil, true),
            (["test"], false)
        ]
    )
    func verifyCanAddNewTags(result: [String]?, expectedCanAddNewTag: Bool) async {
        let nodeSearcher = MockNodeTagsSearcher(tags: nil)
        let sut = makeSUT(nodeSearcher: nodeSearcher)
        sut.tagName = "test"
        sut.onTagNameChanged(with: "test")
        while await nodeSearcher.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeSearcher.continuations.first?.resume(with: .success(result))
        for await canAddNewTag in sut.$canAddNewTag.dropFirst().values {
            #expect(canAddNewTag == expectedCanAddNewTag)
            break
        }
    }

    @MainActor
    @Test("Verify the containsExistingTags when the first search call is cancelled and the second one is successful")
    func verifyContainsExistingTagsWithMultipleSearchCallsInProgress() async {
        let nodeSearcher = MockNodeTagsSearcher(tags: nil)
        let sut = makeSUT(nodeSearcher: nodeSearcher)
        sut.tagName = "test"

        var isLoadingValuesList = [Bool]()
        let cancellable = sut.existingTagsViewModel
            .$isLoading
            .dropFirst()
            .sink { updatedValue in
                isLoadingValuesList.append(updatedValue)
            }

        sut.onTagNameChanged(with: "test")
        while await nodeSearcher.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        sut.onTagNameChanged(with: "tester")
        while await nodeSearcher.continuations.count == 2 {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        await nodeSearcher.continuations.first?.resume(with: .success(["test"]))
        await nodeSearcher.continuations.last?.resume(with: .success([]))

        for await canAddNewTag in sut.$canAddNewTag.dropFirst().values {
            #expect(canAddNewTag == true)
            break
        }
        #expect(isLoadingValuesList == [true, true, false])
        cancellable.cancel()
    }

    @MainActor
    @Test("Verify onTagNameChanged with valid state first and then invalid state")
    func verifyOnTagNameChangedWithValidStateAndThenInvalidState() async {
        // setup
        let nodeSearcher = MockNodeTagsSearcher(tags: nil)
        let sut = makeSUT(nodeSearcher: nodeSearcher)
        sut.tagName = "ta"

        // Test for valid state
        sut.onTagNameChanged(with: "tag")
        while await nodeSearcher.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeSearcher.continuations.first?.resume(with: .success(["tag1", "tag2"]))
        for await canAddNewTag in sut.$canAddNewTag.dropFirst().values {
            #expect(canAddNewTag == true)
            break
        }
        #expect(sut.containsExistingTags == true)

        // Test for invalid state
        sut.onTagNameChanged(with: "tag1😄")
        #expect(sut.canAddNewTag == false)
        #expect(sut.containsExistingTags == false)
    }

    @MainActor
    private func makeSUT(nodeSearcher: some NodeTagsSearching = MockNodeTagsSearcher()) -> ManageTagsViewModel {
        ManageTagsViewModel(
            navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
            existingTagsViewModel: ExistingTagsViewModel(
                tagsViewModel: NodeTagsViewModel(tagViewModels: []),
                nodeTagSearcher: nodeSearcher,
                isSelectionEnabled: false
            )
        )
    }
}
