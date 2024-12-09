import MEGASwift
import SwiftUI

@MainActor
final class ExistingTagsViewModel: ObservableObject {
    @Published var tagsViewModel: NodeTagsViewModel
    @Published var isLoading: Bool = false
    private let isSelectionEnabled: Bool
    private let nodeTagSearcher: any NodeTagsSearching

    // Holds the tag view models that were already selected at the time of initialization.
    // These are stored separately because during a search operation, these models
    // might be removed from the main search list but should still be tracked and preserved.
    private var selectedTagViewModels: [NodeTagViewModel]

    // Keeps track of the newly added tag view models that were created during the lifecycle of this view model.
    // These are stored separately because during a search operation, these models
    // might be removed from the main search list but should still be tracked and preserved.
    private var newlyAddedTagViewModels: [NodeTagViewModel] = []

    var containsTags: Bool {
        tagsViewModel.tagViewModels.isNotEmpty
    }

    init(tagsViewModel: NodeTagsViewModel, nodeTagSearcher: some NodeTagsSearching, isSelectionEnabled: Bool) {
        self.tagsViewModel = tagsViewModel
        self.selectedTagViewModels = tagsViewModel.tagViewModels.filter(\.isSelected)
        self.nodeTagSearcher = nodeTagSearcher
        self.isSelectionEnabled = isSelectionEnabled
    }

    // MARK: - Interface methods.
    
    func addAndSelectNewTag(_ tag: String) {
        let tagViewModel = NodeTagViewModel(tag: tag, isSelectionEnabled: isSelectionEnabled, isSelected: true)
        newlyAddedTagViewModels.append(tagViewModel)
        tagsViewModel.prepend(tagViewModel: tagViewModel)
    }

    func contains(_ tagName: String) -> Bool {
        tagsViewModel.tagViewModels.contains { $0.tag == tagName }
    }

    func searchTags(for searchText: String?) async {
        isLoading = true
        defer {
            /// If a task is cancelled, it means there a new task in progress.
            /// We do not want to reset the isLoading while there is request in progress.
            if !Task.isCancelled {
                isLoading = false
            }
        }

        guard let tags = await nodeTagSearcher.searchTags(for: searchText), !Task.isCancelled else { return }
        tagsViewModel.updateTagsReorderedBySelection(
            filterNewlyAddedTagViewModels(for: searchText) + tagViewModels(for: tags)
        )
    }

    // MARK: - Private methods.

    private func tagViewModels(for tags: [String]) -> [NodeTagViewModel] {
        tags.map { tag in
            if let viewModel = selectedTagViewModels.first(where: { $0.tag == tag }) {
                return viewModel
            } else if let viewModel = tagsViewModel.tagViewModels.first(where: { $0.tag == tag }) {
                return viewModel
            } else {
                return NodeTagViewModel(tag: tag, isSelectionEnabled: isSelectionEnabled, isSelected: false)
            }
        }
    }

    private func filterNewlyAddedTagViewModels(for searchText: String?) -> [NodeTagViewModel] {
        if let searchText {
            return newlyAddedTagViewModels.filter { $0.tag.contains(searchText) }
        } else {
            return newlyAddedTagViewModels
        }
    }
}
