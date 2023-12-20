import Foundation
import MEGADomain

public struct MockPreferenceRepository: PreferenceRepositoryProtocol {
    public var userDefaults: [String: Any]
    
    public static var newRepo: MockPreferenceRepository {
        MockPreferenceRepository()
    }

    public init() {
        userDefaults = [String: Any]()
    }
    
    public subscript<T>(key: String) -> T? {
        get {
            userDefaults[key] as? T
        }
        set {
            userDefaults[key] = newValue
        }
    }
    
    public var isEmpty: Bool {
        userDefaults.isEmpty
    }
}
