import Foundation

@MainActor
final class NodeTagsViewModel: ObservableObject {
    @Published var tagViewModels: [NodeTagViewModel]
    @Published var viewWidth: CGFloat = 0
    @Published private(set) var tagsWidth: [String: CGFloat] = [:]

    init(tagViewModels: [NodeTagViewModel] = []) {
        self.tagViewModels = tagViewModels
    }

    func update(_ tag: String, with width: CGFloat) {
        guard tagViewModels.contains(where: { $0.tag == tag }) else { return }
        tagsWidth[tag] = width
    }
}
