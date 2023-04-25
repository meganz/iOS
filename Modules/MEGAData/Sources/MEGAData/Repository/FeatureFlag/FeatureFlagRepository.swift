import MEGADomain
import Foundation

public final class FeatureFlagRepository: FeatureFlagRepositoryProtocol {
    
    private enum Constants {
        static let userDefaultsDomainName: String = "FeatureFlagDomainName"
    }
    
    public static var newRepo: FeatureFlagRepository {
        FeatureFlagRepository(userDefaults: UserDefaults(suiteName: Constants.userDefaultsDomainName)!)
    }
    
    private let userDefaults: UserDefaults
    private var preferenceRepository: PreferenceRepository

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.preferenceRepository = PreferenceRepository(userDefaults: userDefaults)
    }
    
    public func savedFeatureFlags() -> [FeatureFlagEntity] {
        guard let list = userDefaults.persistentDomain(forName: Constants.userDefaultsDomainName) else {
            return []
        }
        
        var flagList = [FeatureFlagEntity]()
        for flag in list {
            guard let value = flag.value as? Bool else { continue }
            flagList.append(FeatureFlagEntity(name: flag.key, isEnabled: value))
        }
        return flagList
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool {
        userDefaults.bool(forKey: key)
    }
    
    public func configFeatureFlag(for key: FeatureFlagName, isEnabled: Bool) {
        preferenceRepository[key] = isEnabled
    }
    
    public func removeFeatureFlag(for key: FeatureFlagName) {
        preferenceRepository[key] = Optional<Bool>.none
    }
}
