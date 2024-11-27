import AsyncAlgorithms
import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellViewModel: ObservableObject, Sendable {
    private let node: NodeEntity
    private let isSelectionAvailable: Bool = false

    var tags: [String] { node.tags }

    private(set) lazy var nodeTagsViewModel = {
        NodeTagsViewModel(
            tagViewModels: node.tags.map {
                NodeTagViewModel(tag: $0, isSelectionEnabled: isSelectionAvailable, isSelected: isSelectionAvailable)
            }
        )
    }()

    init(node: NodeEntity) {
        self.node = node
    }
}
