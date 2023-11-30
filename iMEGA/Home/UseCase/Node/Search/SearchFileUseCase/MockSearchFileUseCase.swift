import Foundation
@testable import MEGA
import MEGADomain
import MEGAFoundation

final class MockSearchFileUseCase: SearchFileUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let nodeList: NodeListEntity?

    init(
        nodes: [NodeEntity] = [],
        nodeList: NodeListEntity? = nil
    ) {
        self.nodes = nodes
        self.nodeList = nodeList
    }

    func searchFiles(
        withName name: String,
        recursive: Bool,
        nodeType: MEGANodeType?,
        nodeFormat: MEGANodeFormatType?,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        passedInSortOrders.append(sortOrder)
        completion(nodes.filter { $0.name.contains(name) })
    }

    func searchFiles(
        withName name: String,
        recursive: Bool,
        nodeType: MEGANodeType?,
        nodeFormat: MEGANodeFormatType?,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping (NodeListEntity?) -> Void
    ) {
        passedInSortOrders.append(sortOrder)

        guard let nodeList else {
            completion(nil)
            return
        }

        var nodes: [NodeEntity] = []
        for i in 0...nodeList.nodesCount-1 {
            if let nodeAt = nodeList.nodeAt(i) {
                nodes.append(nodeAt)
            }
        }

        let filteredNodes = nodes.filter { $0.name.contains(name) }
        completion(.init(nodesCount: filteredNodes.count, nodeAt: { filteredNodes[$0]}))
    }

    var passedInSortOrders: [MEGASortOrderType?] = []

    func cancelCurrentSearch() {}
}
