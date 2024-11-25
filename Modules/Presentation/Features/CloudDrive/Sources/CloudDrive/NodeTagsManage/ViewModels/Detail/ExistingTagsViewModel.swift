import MEGASwift
import SwiftUI

@MainActor
final class ExistingTagsViewModel: ObservableObject {
    @Published var tagsViewModel: NodeTagsViewModel
    @Published var isLoading: Bool = false
    private let isSelectionEnabled: Bool
    private let nodeTagSearcher: any NodeTagsSearching

    var containsTags: Bool {
        tagsViewModel.tagViewModels.isNotEmpty
    }

    init(tagsViewModel: NodeTagsViewModel, nodeTagSearcher: some NodeTagsSearching, isSelectionEnabled: Bool) {
        self.tagsViewModel = tagsViewModel
        self.nodeTagSearcher = nodeTagSearcher
        self.isSelectionEnabled = isSelectionEnabled
    }

    func addAndSelectNewTag(_ tag: String) {
        let tagViewModel = NodeTagViewModel(tag: tag, isSelectionEnabled: isSelectionEnabled, isSelected: true)
        tagsViewModel.prepend(tagViewModel: tagViewModel)
    }

    func searchTags(for searchText: String?) async {
        isLoading = true
        defer { isLoading = false }

        guard let tags = await nodeTagSearcher.searchTags(for: searchText), !Task.isCancelled else { return }
        updateUI(for: tags)
    }

    private func updateUI(for tags: [String]) {
        let tagViewModels = tags.map { tag in
            guard let viewModel = tagsViewModel.tagViewModels.first(where: { $0.tag == tag }) else {
                return NodeTagViewModel(tag: tag, isSelectionEnabled: isSelectionEnabled, isSelected: false)
            }

            return viewModel
        }
        tagsViewModel.updateTagsReorderedBySelection(tagViewModels)
    }
}
