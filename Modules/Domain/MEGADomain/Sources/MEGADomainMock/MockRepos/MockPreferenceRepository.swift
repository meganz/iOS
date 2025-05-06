import Foundation
import MEGADomain
import MEGAPreference
import MEGASwift

public final class MockPreferenceRepository: PreferenceRepositoryProtocol, @unchecked Sendable {
    public subscript<T>(key: String) -> T? {
        get {
            userDefaults[key] as? T
        }
        set {
            $userDefaults.mutate { $0[key] = newValue }
        }
    }
    
    @Atomic public var userDefaults: [String: Any] = [:]
    
    public static var newRepo: MockPreferenceRepository {
        MockPreferenceRepository()
    }
    
    public init() {}
       
    public var isEmpty: Bool {
        userDefaults.isEmpty
    }
}
