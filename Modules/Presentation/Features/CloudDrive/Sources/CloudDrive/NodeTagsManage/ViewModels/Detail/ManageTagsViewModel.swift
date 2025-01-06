import Combine
import MEGADomain
import MEGASDKRepo
import MEGASwift
import SwiftUI

@MainActor
final class ManageTagsViewModel: ObservableObject {
    enum TagNameState {
        case empty
        case invalid
        case tooLong
        case valid
    }

    // `doneButtonDisabled` will be handled in [SAO-1819]
    let navigationBarViewModel: ManageTagsViewNavigationBarViewModel
    let existingTagsViewModel: ExistingTagsViewModel

    @Published var tagName: String = ""

    @Published var tagNameState: TagNameState = .empty
    @Published var containsExistingTags: Bool
    @Published var canAddNewTag: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isCurrentlySavingTags: Bool = false
    private let nodeTagsUseCase: any NodeTagsUseCaseProtocol
    private var nodeEntity: NodeEntity
    private var maxAllowedCharacterCount = 32
    private var subscriptions: Set<AnyCancellable> = []
    private var searchingTask: Task<Void, Never>?
    private var currentNodeTagsUpdatesSequenceTask: Task<Void, Never>?
    private var monitorDoneButtonTask: Task<Void, Never>?

    var shouldShowOverviewView: Bool {
        containsExistingTags
        || (!existingTagsViewModel.isLoading
            && !containsExistingTags
            && !canAddNewTag
            && existingTagsViewModel.hasReachedMaxLimit)
    }

    private let tagsUpdatesUseCase: any NodeTagsUpdatesUseCaseProtocol

    init(
        nodeEntity: NodeEntity,
        navigationBarViewModel: ManageTagsViewNavigationBarViewModel,
        existingTagsViewModel: ExistingTagsViewModel,
        tagsUpdatesUseCase: some NodeTagsUpdatesUseCaseProtocol,
        nodeTagsUseCase: some NodeTagsUseCaseProtocol
    ) {
        self.nodeEntity = nodeEntity
        self.navigationBarViewModel = navigationBarViewModel
        self.existingTagsViewModel = existingTagsViewModel
        self.nodeTagsUseCase = nodeTagsUseCase
        containsExistingTags = existingTagsViewModel.containsTags
        self.tagsUpdatesUseCase = tagsUpdatesUseCase
        monitorTagViewModelListUpdates()
        monitorCancelButtonTap()
        monitorDoneButtonTap()
        updateDoneButtonStatus()
        monitorHasReachedMaxLimitUpdates()
    }

    deinit {
        currentNodeTagsUpdatesSequenceTask?.cancel()
        monitorDoneButtonTask?.cancel()
    }

    // MARK: - Interface methods.
    func observeTagsUpdates() async {
        for await event in tagsUpdatesUseCase.tagsUpdates(for: nodeEntity) {
            switch event {
            case .tagsUpdated:
                await existingTagsViewModel.reloadData()
                onTagNameChanged(with: tagName)
            case .tagsInvalidated:
                navigationBarViewModel.cancelButtonTapped = true
            }
        }
    }

    func addTag() {
        guard tagNameState == .valid else { return }
        existingTagsViewModel.addAndSelectNewTag(tagName)
        containsExistingTags = true
        tagName = ""
    }

    func onTagNameChanged(with updatedTagName: String) {
        let formattedTagName = formatTagName(updatedTagName)
        updateTagNameState(for: formattedTagName)

        searchingTask?.cancel()
        canAddNewTag = false

        if tagNameState == .valid || tagNameState == .empty {
            searchingTask = searchTags(for: formattedTagName == "" ? nil : formattedTagName)
        } else if tagNameState == .invalid || tagNameState == .tooLong {
            containsExistingTags = false
        }

        guard updatedTagName != formattedTagName else { return }
        tagName = formattedTagName
    }

    func clearTextField() {
        tagName = ""
        tagNameState = .empty
    }

    func loadAllTags() async {
        await searchTags(for: nil).value
    }

    func cancelSearchingIfNeeded() {
        searchingTask?.cancel()
    }

    // MARK: - Private methods

    private func searchTags(for text: String?) -> Task<Void, Never> {
        Task {
            await existingTagsViewModel.searchTags(for: text)
        }
    }

    private func formatTagName(_ tagName: String) -> String {
        if tagName.hasPrefix("#") {
            return String(tagName.drop(while: { $0 == "#" }))
        } else if containsUpperCaseCharacters(in: tagName) {
            return tagName.lowercased()
        } else {
            return tagName
        }
    }

    private func updateTagNameState(for updatedTagName: String) {
        if updatedTagName.isEmpty {
            tagNameState = .empty
        } else if containsInvalidCharacters(in: updatedTagName) {
            tagNameState = .invalid
        } else if updatedTagName.count > maxAllowedCharacterCount {
            tagNameState = .tooLong
        } else {
            tagNameState = .valid
        }
    }

    private func containsInvalidCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
    }

    private func containsUpperCaseCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil
    }

    private func monitorTagViewModelListUpdates() {
        existingTagsViewModel
            .tagsViewModel
            .$tagViewModels
            .dropFirst()
            .sink { [weak self] tagViewModels in
                guard let self else { return }
                containsExistingTags = tagViewModels.isNotEmpty
                updateCanAddNewTag(with: tagViewModels, isUnderLimit: !existingTagsViewModel.hasReachedMaxLimit)
            }
            .store(in: &subscriptions)
    }

    private func monitorHasReachedMaxLimitUpdates() {
        existingTagsViewModel
            .$hasReachedMaxLimit
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self else { return }
                updateCanAddNewTag(with: existingTagsViewModel.tagsViewModel.tagViewModels, isUnderLimit: !newValue)
            }
            .store(in: &subscriptions)
    }

    private func updateCanAddNewTag(with tagViewModels: [NodeTagViewModel], isUnderLimit: Bool) {
        let isNotEmpty = !tagName.isEmpty
        let isUnique = !tagViewModels.contains { $0.tag == tagName }
        canAddNewTag = isNotEmpty && isUnderLimit && isUnique
    }

    private func monitorCancelButtonTap() {
        navigationBarViewModel
            .$cancelButtonTapped
            .sink { [weak self] cancelButtonTapped in
                guard let self else { return }
                shouldDismiss = cancelButtonTapped
            }
            .store(in: &subscriptions)
    }

    private func monitorDoneButtonTap() {
        monitorDoneButtonTask = Task { [weak self, navigationBarViewModel] in
            for await _ in navigationBarViewModel.$doneButtonTapped.values.dropFirst() {
                await self?.commitTagUpdates()
            }
        }
    }

    private func commitTagUpdates() async {
        isCurrentlySavingTags = true
        navigationBarViewModel.doneButtonDisabled = true

        let removedTags = existingTagsViewModel.currentlyAttachedTags.subtracting(existingTagsViewModel.currentNodeTags)
        let addedTags = existingTagsViewModel.currentNodeTags.subtracting(existingTagsViewModel.currentlyAttachedTags)

        // Remove existing tags first, then add new tags to avoid errors when the tag limit is reached.
        for removedTag in removedTags {
            do {
                try await nodeTagsUseCase.remove(tag: removedTag, from: nodeEntity)
            } catch {
                // Todo: Show error if saving failed.
            }
        }

        for addedTag in addedTags {
            do {
                try await nodeTagsUseCase.add(tag: addedTag, to: nodeEntity)
            } catch {
                // Todo: Show error if saving failed.
            }
        }

        isCurrentlySavingTags = false
        shouldDismiss = true
    }

    private func updateDoneButtonStatus() {
        currentNodeTagsUpdatesSequenceTask = Task { [existingTagsViewModel, navigationBarViewModel] in
            for await hasChanges in existingTagsViewModel.hasUnsavedNodeTagsChangesSequence {
                navigationBarViewModel.doneButtonDisabled = !hasChanges
            }
        }
    }
}
