import Foundation
import MEGADomain

public struct PreferenceRepository: PreferenceRepositoryProtocol {
    public static var newRepo: PreferenceRepository {
        PreferenceRepository(userDefaults: UserDefaults.standard)
    }
    
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    public subscript<T>(key: String) -> T? {
        get {
            userDefaults.object(forKey: key) as? T
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}
