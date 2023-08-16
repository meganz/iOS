import Foundation
import MEGADomain

final public class MockShareRepository: ShareRepositoryProtocol {
    public static var newRepo: MockShareRepository {
        MockShareRepository()
    }
    
    private let sharingUser: UserEntity?
    private let areUserCredentialsVerified: Bool
    
    public init(sharingUser: UserEntity? = nil, areUserCredentialsVerified: Bool = false) {
        self.sharingUser = sharingUser
        self.areUserCredentialsVerified = areUserCredentialsVerified
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

    public func areCredentialsVerifed(of user: UserEntity) -> Bool {
        areUserCredentialsVerified
    }
    
    public func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
        return node.handle
    }
}
