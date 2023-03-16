import MEGADomain

public final class MockSearchNodeRepository: SearchNodeRepositoryProtocol {
    public static var newRepo: MockSearchNodeRepository {
        MockSearchNodeRepository()
    }
    
    private let nodes: [NodeEntity]
    public var cancelSearch_calledTimes: Int
    
    public init(nodes: [NodeEntity] = [], cancelSearch_calledTimes: Int = 0) {
        self.nodes = nodes
        self.cancelSearch_calledTimes = cancelSearch_calledTimes
    }
    
    public func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity] {
        nodes.filter { node in
            node.name.contains(text)
        }
    }
    
    public func cancelSearch() {
        cancelSearch_calledTimes += 1
    }
}
