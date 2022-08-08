import Foundation
import MEGADomain

struct PreferenceRepository: PreferenceRepositoryProtocol {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    subscript<T>(key: String) -> T? {
        get {
            userDefaults.object(forKey: key) as? T
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}
