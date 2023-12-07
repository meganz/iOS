import Foundation
@testable import MEGA
import MEGADomain
import MEGAFoundation

final class MockSearchFileUseCase: SearchFileUseCaseProtocol {
    var nodesToReturnFactory: ((MEGASearchFilter) -> NodeListEntity?)?

    private let nodes: [NodeEntity]
    private let nodeList: NodeListEntity?

    init(
        nodes: [NodeEntity] = [],
        nodeList: NodeListEntity? = nil,
        nodesToReturnFactory: ((MEGASearchFilter) -> NodeListEntity?)? = nil
    ) {
        self.nodes = nodes
        self.nodeList = nodeList
        self.nodesToReturnFactory = nodesToReturnFactory
    }

    func searchFiles(
        withFilter filter: MEGASearchFilter,
        recursive: Bool,
        sortOrder: MEGASortOrderType?,
        searchPath: MEGA.SearchFileRootPath,
        completion: @escaping (MEGADomain.NodeListEntity?
        ) -> Void) {
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
        guard let factory = nodesToReturnFactory else {
            completion(nil)
            return
        }
        completion(factory(filter))
        
    }

    var passedInSortOrders: [MEGASortOrderType?] = []

    func cancelCurrentSearch() {}
}
