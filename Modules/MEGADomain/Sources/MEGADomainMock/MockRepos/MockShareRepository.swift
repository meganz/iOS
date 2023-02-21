import Foundation
import MEGADomain

public struct MockShareRepository: ShareRepositoryProtocol {
    public static var newRepo: MockShareRepository {
        MockShareRepository(sharedNodeHandle: 0)
    }
    
    private let sharedNodeHandle: HandleEntity
    private let sharingUser: UserEntity?
    
    public init(sharedNodeHandle: HandleEntity = 0,
                sharingUser: UserEntity? = nil) {
        self.sharedNodeHandle = sharedNodeHandle
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
        sharedNodeHandle
    }
}
