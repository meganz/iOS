import Foundation

@MainActor
final class NodeTagsViewModel: ObservableObject {
    @Published private(set) var tagViewModels: [NodeTagViewModel]
    @Published var viewHeight: CGFloat = 0
    let isSelectionEnabled: Bool

    init(tagViewModels: [NodeTagViewModel] = [], isSelectionEnabled: Bool) {
        self.tagViewModels = tagViewModels
        self.isSelectionEnabled = isSelectionEnabled
    }

    func prepend(tagViewModel: NodeTagViewModel) {
        tagViewModels.insert(tagViewModel, at: 0)
    }

    func updateTagsReorderedBySelection(_ tagViewModels: [NodeTagViewModel]) {
        self.tagViewModels = tagViewModels.sorted { $0.isSelected && !$1.isSelected }
    }
}
