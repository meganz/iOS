import Foundation

@MainActor
final class NodeTagsViewModel: ObservableObject {
    @Published var tagViewModels: [NodeTagViewModel]
    @Published var viewHeight: CGFloat = 0

    init(tagViewModels: [NodeTagViewModel] = []) {
        self.tagViewModels = tagViewModels
    }

    func prepend(tagViewModel: NodeTagViewModel) {
        tagViewModels.insert(tagViewModel, at: 0)
    }

    func updateTagsReorderedBySelection(_ tagViewModels: [NodeTagViewModel]) {
        self.tagViewModels = tagViewModels.sorted { $0.isSelected && !$1.isSelected }
    }
}
