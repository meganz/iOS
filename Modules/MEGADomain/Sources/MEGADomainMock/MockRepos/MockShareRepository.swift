import Foundation
import MEGADomain

final public class MockShareRepository: ShareRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockShareRepository = MockShareRepository()
    
    private let sharingUser: UserEntity?
    public private(set) var sharedNodeHandles = [HandleEntity]()
    
    public init(sharingUser: UserEntity? = nil) {
        self.sharingUser = sharingUser
    }
    
    public func user(sharing node: NodeEntity) -> UserEntity? {
        sharingUser
    }
    
    public  func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        [NodeEntity()]
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        [ShareEntity()]
    }
    
    public func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
        sharedNodeHandles.append(node.handle)
        return node.handle
    }
}
