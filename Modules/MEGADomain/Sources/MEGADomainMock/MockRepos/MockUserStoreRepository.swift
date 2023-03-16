import Foundation
import MEGADomain

public struct MockUserStoreRepository: UserStoreRepositoryProtocol {
    public static var newRepo: MockUserStoreRepository {
        MockUserStoreRepository()
    }
    
    private let displayName: String?
    
    public init(displayName: String? = nil) {
        self.displayName = displayName
    }
    
    public func getDisplayName(forUserHandle handle: UInt64) -> String? {
        displayName
    }
    
    public func displayName(forUserHandle handle: HandleEntity) async -> String? {
        displayName
    }
}
