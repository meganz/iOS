import Foundation
import MEGADomain

public struct MockUserStoreRepository: UserStoreRepositoryProtocol {
    
    public static var newRepo: MockUserStoreRepository {
        MockUserStoreRepository()
    }
    
    private let displayName: String?
    private let firstName: String?
    private let lastName: String?
    
    public init(
        displayName: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil
    ) {
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
    }
    
    public func getDisplayName(forUserHandle handle: UInt64) -> String? {
        displayName
    }
    
    public func displayName(forUserHandle handle: HandleEntity) async -> String? {
        displayName
    }
    
    public func userDisplayName(forEmail email: String) -> String? {
        displayName
    }
    
    public func userFirstName(withHandle handle: UInt64) -> String? {
        firstName
    }
    
    public func userLastName(withHandle handle: UInt64) -> String? {
        lastName
    }
}
