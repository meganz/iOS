import Foundation
import MEGADomain

final public class MockFileSearchRepository: NSObject, FileSearchRepositoryProtocol {
    public static var newRepo: MockFileSearchRepository {
        MockFileSearchRepository(nodes: [NodeEntity(handle: 1)])
    }
    
    private var nodes: [NodeEntity]
    public var callback: (([NodeEntity]) -> Void)?
    
    public init(nodes: [NodeEntity]) {
        self.nodes = nodes
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        nodes
    }
    
    public func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        self.callback = callback
    }
    
    public func stopMonitoringNodesUpdate() {
        self.callback = nil
    }
}
