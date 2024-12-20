import Combine
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
final class ExistingTagsViewModel: ObservableObject {
    private struct TagSelectionLimit {
        let maxTagsAllowed: Int
        let alertMessage: String

        static var instance: TagSelectionLimit {
            .init(
                maxTagsAllowed: 10,
                alertMessage: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.Selection.maxLimitReachedAlertMessage
            )
        }
    }

    @Published var tagsViewModel: NodeTagsViewModel
    @Published var isLoading = false
    @Published var hasReachedMaxLimit: Bool
    @Published var snackBar: SnackBar?

    private let nodeTagSearcher: any NodeTagsSearching
    private var subscriptions: Set<AnyCancellable> = []

    /// A set of selected tags.
    private var selectedTags: Set<String>
    /// A list of newly added tags.
    private var newlyAddedTags: [String] = []
    /// A snapshot of the current tags before sorting is applied.
    private var tagsSnapshot: [String]

    private let tagSelectionLimit: TagSelectionLimit = .instance

    var containsTags: Bool {
        tagsViewModel.tagViewModels.isNotEmpty
    }

    var maxLimitReachedAlertMessage: String {
        tagSelectionLimit.alertMessage
    }

    init(tagsViewModel: NodeTagsViewModel, nodeTagSearcher: some NodeTagsSearching) {
        self.tagsViewModel = tagsViewModel
        let tagViewModels = tagsViewModel.tagViewModels
        let selectedTags = Set(tagViewModels.compactMap { $0.isSelected ? $0.tag : nil })
        self.selectedTags = selectedTags
        self.tagsSnapshot = tagViewModels.map(\.tag)
        self.nodeTagSearcher = nodeTagSearcher
        hasReachedMaxLimit = selectedTags.count >= tagSelectionLimit.maxTagsAllowed
        observeTogglesIfRequired(for: tagViewModels)
    }

    // MARK: - Interface methods.
    
    func addAndSelectNewTag(_ tag: String) {
        newlyAddedTags.insert(tag, at: 0)

        let tagViewModel = makeNodeTagViewModel(with: tag, isSelected: true)
        tagsViewModel.prepend(tagViewModel: tagViewModel)
        updateMaxSelectedTagsStatus()
    }

    func searchTags(for searchText: String?) async {
        isLoading = true
        guard let tags = await nodeTagSearcher.searchTags(for: searchText), !Task.isCancelled else { return }
        tagsSnapshot = tags
        let newlyAddedTagsViewModel = filterNewlyAddedTags(for: searchText)
            .map { makeNodeTagViewModel(with: $0, isSelected: true) }
        tagsViewModel.updateTagsReorderedBySelection(newlyAddedTagsViewModel + tagViewModels(for: tags))
        isLoading = false
    }

    // MARK: - Private methods.

    private func tagViewModels(for tags: [String]) -> [NodeTagViewModel] {
        tags.map { tag in
            if let viewModel = tagsViewModel.tagViewModels.first(where: { $0.tag == tag }) {
                viewModel
            } else {
                makeNodeTagViewModel(with: tag, isSelected: selectedTags.contains(tag))
            }
        }
    }

    private func filterNewlyAddedTags(for searchText: String?) -> [String] {
        if let searchText {
            newlyAddedTags.filter {
                $0.range(of: searchText, options: [.diacriticInsensitive, .caseInsensitive]) != nil
            }
        } else {
            newlyAddedTags
        }
    }

    private func observeTogglesIfRequired(for tagViewModels: [NodeTagViewModel]) {
        guard tagsViewModel.isSelectionEnabled else { return }
        tagViewModels.forEach { observeToggles(for: $0) }
    }

    private func observeToggles(for tagViewModel: NodeTagViewModel) {
        tagViewModel
            .observeToggles()
            .sink { [weak self, weak tagViewModel] tag in
                guard let self, let tagViewModel else { return }

                if showSelectedTagsMaxLimitReachedToastIfNeeded(for: tag) {
                    return
                }

                if newlyAddedTags.contains(tag) {
                    removeDeselectedNewlyAddedTags(tagViewModel: tagViewModel)
                } else {
                    toggleTagSelectionAndRearrange(tagViewModel: tagViewModel)
                }

                updateMaxSelectedTagsStatus()
            }
            .store(in: &subscriptions)
    }

    private func removeDeselectedNewlyAddedTags(tagViewModel: NodeTagViewModel) {
        newlyAddedTags.removeAll(where: { $0 == tagViewModel.tag })

        var tagViewModels = tagsViewModel.tagViewModels
        tagViewModels.removeAll(where: { $0.tag == tagViewModel.tag })
        tagsViewModel.updateTagsReorderedBySelection(tagViewModels)
    }

    private func removeDeselectedTagsFromSelectedTags(tagViewModel: NodeTagViewModel) {
        selectedTags.remove(tagViewModel.tag)
        toggleTagSelectionAndRearrange(tagViewModel: tagViewModel)
    }

    private func selected(tagViewModel: NodeTagViewModel) {
        selectedTags.insert(tagViewModel.tag)
        toggleTagSelectionAndRearrange(tagViewModel: tagViewModel)
    }

    private func toggleTagSelectionAndRearrange(tagViewModel: NodeTagViewModel) {
        let displayedTagViewModels = tagsViewModel.tagViewModels

        let filteredNewlyAddedTagViewModels = newlyAddedTags.compactMap { newlyAddedTag in
            displayedTagViewModels.first(where: { $0.tag == newlyAddedTag })
        }

        let searchSnapshotTagViewModels = tagsSnapshot.compactMap { tag in
            if let viewModel = displayedTagViewModels.first(where: { $0.tag == tag }) {
                if viewModel.tag == tagViewModel.tag {
                    let newSelectionState = !tagViewModel.isSelected
                    updateTagSelection(for: tagViewModel.tag, isSelected: newSelectionState)
                    return makeNodeTagViewModel(with: tag, isSelected: newSelectionState)
                } else {
                    return viewModel
                }
            } else {
                assertionFailure("Unsuccessful finding the tag view model and this should never happen")
                return nil
            }
        }

        tagsViewModel.updateTagsReorderedBySelection(filteredNewlyAddedTagViewModels + searchSnapshotTagViewModels)
    }

    private func makeNodeTagViewModel(with tag: String, isSelected: Bool) -> NodeTagViewModel {
        let viewModel = NodeTagViewModel(tag: tag, isSelected: isSelected)
        observeToggles(for: viewModel)
        return viewModel
    }

    private func updateTagSelection(for tag: String, isSelected: Bool) {
        if isSelected {
            selectedTags.insert(tag)
        } else {
            selectedTags.remove(tag)
        }
    }

    private func updateMaxSelectedTagsStatus() {
        withAnimation {
            hasReachedMaxLimit = (selectedTags.count + newlyAddedTags.count) >= tagSelectionLimit.maxTagsAllowed
        }
    }

    private func showSelectedTagsMaxLimitReachedToastIfNeeded(for tag: String) -> Bool {
        guard hasReachedMaxLimit, selectedTags.notContains(tag), newlyAddedTags.notContains(tag) else {
            snackBar = nil
            return false
        }

        snackBar = SnackBar(
            message: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.Selection.maxLimitReachedAlertMessage
        )
        return true
    }
}
