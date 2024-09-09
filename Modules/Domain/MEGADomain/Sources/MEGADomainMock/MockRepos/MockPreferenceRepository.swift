import Foundation
import MEGADomain
import MEGASwift

public final class MockPreferenceRepository: PreferenceRepositoryProtocol, @unchecked Sendable {
    @Atomic public var userDefaults: [String: Any] = [:]
    
    public static var newRepo: MockPreferenceRepository {
        MockPreferenceRepository()
    }
    
    public init() {}
    
    public func value<T>(forKey key: String) -> T? {
        userDefaults[key] as? T
    }
    
    public func setValue<T>(value: T?, forKey key: String) {
        $userDefaults.mutate { $0[key] = value }
    }
    
    public var isEmpty: Bool {
        userDefaults.isEmpty
    }
}
