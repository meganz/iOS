@testable import CloudDrive
import Combine
import MEGADomain
import MEGASwift
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
        let sut = makeSUT(nodeTagsUseCase: PrivateMockNodeTagsUseCase(tags: tags))
        #expect(sut.containsExistingTags == false)
        await sut.loadAllTags()
        #expect(sut.containsExistingTags == containsExistingTags)
    }

    @MainActor
    @Test(
        "Verify the canAddNewTag property based on the results returned by the search API call",
        arguments: [
            ([], true),
            (["test"], false)
        ]
    )
    func verifyCanAddNewTags(result: [String]?, expectedCanAddNewTag: Bool) async {
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: nil)
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.tagName = "test"
        sut.onTagNameChanged(with: "test")
        while await nodeTagsUseCase.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeTagsUseCase.continuations.first?.resume(with: .success(result))
        for await canAddNewTag in sut.$canAddNewTag.dropFirst().values {
            #expect(canAddNewTag == expectedCanAddNewTag)
            break
        }
    }

    @MainActor
    @Test("Verify the containsExistingTags when the first search call is cancelled and the second one is successful")
    func verifyContainsExistingTagsWithMultipleSearchCallsInProgress() async {
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: nil)
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.tagName = "test"

        var isLoadingValuesList = [Bool]()
        let cancellable = sut.existingTagsViewModel
            .$isLoading
            .dropFirst()
            .sink { updatedValue in
                isLoadingValuesList.append(updatedValue)
            }

        sut.onTagNameChanged(with: "test")
        while await nodeTagsUseCase.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        sut.onTagNameChanged(with: "tester")
        while await nodeTagsUseCase.continuations.count == 2 {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        await nodeTagsUseCase.continuations.first?.resume(with: .success(["test"]))
        await nodeTagsUseCase.continuations.last?.resume(with: .success([]))

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
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: nil)
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.tagName = "ta"

        // Test for valid state
        sut.onTagNameChanged(with: "tag")
        while await nodeTagsUseCase.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeTagsUseCase.continuations.first?.resume(with: .success(["tag1", "tag2"]))
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
    @Test("Verify valid search followed by invalid text field entry")
    func verifyValidSearchFollowedByInvalidTextFieldEntry() async {
        // setup
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: nil)
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.tagName = "ta"

        // Test for valid search Entry first
        sut.onTagNameChanged(with: "tag")
        // Next, Test for invalid search Entry next
        sut.onTagNameChanged(with: "tag1😄")

        // Next, fulfill the search for the first entry
        while await nodeTagsUseCase.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeTagsUseCase.continuations.first?.resume(with: .success(["tag1", "tag2"]))

        // The app should not allow to add new tag and also no existing tags should be shown
        #expect(sut.canAddNewTag == false)
        #expect(sut.containsExistingTags == false)
    }

    @MainActor
    @Test("Verify cancel searching")
    func verifySearchingCancellationWhenViewDisappears() async {
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: nil)
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.tagName = "ta"

        sut.onTagNameChanged(with: "tag")

        // Cancel the searching task
        sut.cancelSearchingIfNeeded()

        // Next, fulfill the search for the first entry
        while await nodeTagsUseCase.continuations.first == nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        await nodeTagsUseCase.continuations.first?.resume(with: .success(["tag1", "tag2"]))

        #expect(sut.canAddNewTag == false)
        #expect(sut.containsExistingTags == false)
    }

    @MainActor
    @Test("Verify adding a new tag and remove it given it is a new account")
    func verifyAddingNewTagAndRemovingItGivenItIsANewAccount() async throws {
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: [])
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.tagName = ""
        sut.onTagNameChanged(with: "")
        sut.tagName = "tag"
        sut.onTagNameChanged(with: "tag")
        sut.addTag()
        #expect(sut.containsExistingTags == true)
        sut.existingTagsViewModel.tagsViewModel.tagViewModels.first?.toggle()
        #expect(sut.containsExistingTags == false)
    }

    @MainActor
    @Test("Verify should show overview")
    func verifyShouldShowOverviewView() {
        let sut = makeSUT()
        sut.existingTagsViewModel.hasReachedMaxLimit = true
        #expect(sut.shouldShowOverviewView == true)
        sut.existingTagsViewModel.isLoading = true
        #expect(sut.shouldShowOverviewView == false)
        sut.existingTagsViewModel.isLoading = false
        sut.canAddNewTag = true
        #expect(sut.shouldShowOverviewView == false)
        sut.canAddNewTag = false
        sut.existingTagsViewModel.hasReachedMaxLimit = false
        #expect(sut.shouldShowOverviewView == false)
    }

    @MainActor
    @Test("Verify Add tag button should not be shown when max limit reached")
    func verifyAddTagButtonWhenMaxLimitReached() async {
        let nodeTagsUseCase = PrivateMockNodeTagsUseCase(tags: [
            "tag1",
            "tag2",
            "tag3",
            "tag4",
            "tag5",
            "tag6",
            "tag7",
            "tag8",
            "tag9"
        ])
        let sut = makeSUT(nodeTagsUseCase: nodeTagsUseCase)
        sut.canAddNewTag = true
        await sut.loadAllTags()
        sut.tagNameState = .valid
        sut.tagName = "tag10"
        sut.addTag()
        #expect(sut.canAddNewTag == false)
    }

    @MainActor
    @Test("Verify adding new tag as the 10th tag and then removing it should show the add tag button")
    func verifyAddingNewTagAsThe10thTagAndThenRemovingItShouldShowTheAddTagButton() async throws {
        let nodeSearcher = PrivateMockNodeTagsUseCase(tags: [
            "tag1",
            "tag2",
            "tag3",
            "tag4",
            "tag5",
            "tag6",
            "tag7",
            "tag8",
            "tag9"
        ])
        let sut = makeSUT(nodeTagsUseCase: nodeSearcher)
        sut.canAddNewTag = true
        await sut.loadAllTags()
        sut.tagNameState = .valid
        sut.tagName = "amo"
        sut.addTag()
        sut.tagName = "amo"
        sut.existingTagsViewModel.tagsViewModel.tagViewModels.filter({ $0.tag == "amo" }).first?.toggle()
        #expect(sut.canAddNewTag == true)
    }

    @MainActor
    private func makeSUT(nodeTagsUseCase: PrivateMockNodeTagsUseCase = PrivateMockNodeTagsUseCase()) -> ManageTagsViewModel {
        ManageTagsViewModel(
            nodeEntity: .init(),
            navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
            existingTagsViewModel: ExistingTagsViewModel(
                nodeEntity: .init(),
                tagsViewModel: NodeTagsViewModel(tagViewModels: [], isSelectionEnabled: false),
                nodeTagsUseCase: nodeTagsUseCase
            ),
            tagsUpdatesUseCase: MockTagsUpdatesUseCase()
        )
    }
}

private actor PrivateMockNodeTagsUseCase: NodeTagsUseCaseProtocol, @unchecked Sendable {
    func getTags(for node: NodeEntity) async -> [String]? { nil }

    private var tags: [String]?
    var continuations: [CheckedContinuation<[String]?, Never>] = []

    init(tags: [String]? = []) {
        self.tags = tags
    }

    func update(tags: [String]?) {
        self.tags = tags
    }

    func searchTags(for searchText: String?) async -> [String]? {
        if let tags {
            guard let searchText else {
                return tags
            }

            return tags.filter { $0.contains(searchText) }
        } else {
            return await withCheckedContinuation { continuation in
                continuations.append(continuation)
            }
        }
    }
}

private final class MockTagsUpdatesUseCase: NodeTagsUpdatesUseCaseProtocol {
    func tagsUpdates(for node: MEGADomain.NodeEntity) -> AnyAsyncSequence<MEGADomain.TagsUpdatesEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
