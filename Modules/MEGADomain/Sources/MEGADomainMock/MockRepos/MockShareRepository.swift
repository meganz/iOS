import Foundation
import MEGADomain

public struct MockShareRepository: ShareRepositoryProtocol {
    
    public static var newRepo: MockShareRepository {
        MockShareRepository(sharedNodeHandle: 0)
    }
    
    private let sharedNodeHandle: HandleEntity
    
    public init(sharedNodeHandle: HandleEntity) {
        self.sharedNodeHandle = sharedNodeHandle
    }
    
    public  func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        [NodeEntity()]
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        [ShareEntity()]
    }
    
    public func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
        sharedNodeHandle
    }
}
