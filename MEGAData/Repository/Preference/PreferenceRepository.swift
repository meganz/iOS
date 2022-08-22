import Foundation
import MEGADomain

struct PreferenceRepository: PreferenceRepositoryProtocol {
    static var newRepo: PreferenceRepository {
        PreferenceRepository(userDefaults: UserDefaults.standard)
    }
    
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
