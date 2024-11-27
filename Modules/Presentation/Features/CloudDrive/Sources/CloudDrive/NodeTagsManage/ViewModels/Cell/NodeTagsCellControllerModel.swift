import Foundation
import MEGADomain

@MainActor
public final class NodeTagsCellControllerModel {
    private let node: NodeEntity
    private(set) lazy var cellViewModel = NodeTagsCellViewModel(node: node)

    var selectedTags: Set<String> {
        Set(node.tags)
    }

    public init(node: NodeEntity) {
        self.node = node
    }
}
