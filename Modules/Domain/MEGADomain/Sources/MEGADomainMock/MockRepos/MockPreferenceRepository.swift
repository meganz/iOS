import Foundation
import MEGADomain

public struct MockPreferenceRepository<U>: PreferenceRepositoryProtocol {
    private var userDefaults: [String: U]
    
    public static var newRepo: MockPreferenceRepository {
        MockPreferenceRepository()
    }

    public init() {
        userDefaults = [String: U]()
    }
    
    public subscript<T>(key: String) -> T? {
        get {
            userDefaults[key] as? T
        }
        set {
            userDefaults[key] = newValue as? U
        }
    }
}
