import Foundation
@testable import MEGA
import MEGADomain
import MEGAFoundation

final class MockSearchFileUseCase: SearchFileUseCaseProtocol {
    private let nodes: [NodeEntity]

    init(
        nodes: [NodeEntity] = []
    ) {
        self.nodes = nodes
    }

    func searchFiles(
        withName name: String,
        nodeFormat: MEGANodeFormatType?,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        passedInSortOrders.append(sortOrder)
        completion(nodes.filter { $0.name.contains(name) })
    }
    
    var passedInSortOrders: [MEGASortOrderType?] = []

    func cancelCurrentSearch() {}
}
