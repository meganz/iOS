import Foundation

@MainActor
final class NodeTagsViewModel: ObservableObject {
    @Published var tags: [String] = []
    @Published var viewWidth: CGFloat = 0
    @Published private(set) var tagsWidth: [String: CGFloat] = [:]

    init(tags: [String]) {
        self.tags = tags
    }

    func update(_ tag: String, with width: CGFloat) {
        guard tags.contains(tag) else { return }
        tagsWidth[tag] = width
    }
}
