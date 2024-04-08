import Foundation
import MEGADomain

public final class FeatureFlagRepository: FeatureFlagRepositoryProtocol {
    
    private enum Constants {
        // instead of keeping feature flags mixed within other values in user defaults, we keep in the
        // then in a nested dictionary under this key
        static let featureFlagsKey: String = "nz.co.mega.feature-flags"
        // this is the shared app group which makes it possible to share state of user defaults
        // between main app target and app extensions
        static let MEGAGroupIdentifier = "group.mega.ios"
    }
    
    public static var newRepo: FeatureFlagRepository {
        FeatureFlagRepository(userDefaults: UserDefaults(suiteName: Constants.MEGAGroupIdentifier)!)
    }
    
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    private var featureFlagsDict: [String: Any] {
        if let dict = userDefaults.object(forKey: Constants.featureFlagsKey) as? [String: Any] {
            return dict
        }
        return [:]
    }
    
    private func save(dict: [String: Any]) {
        userDefaults.set(dict, forKey: Constants.featureFlagsKey)
    }
    
    public func savedFeatureFlags() -> [FeatureFlagEntity] {
        var flagList = [FeatureFlagEntity]()
        for flag in featureFlagsDict {
            guard let value = flag.value as? Bool else { continue }
            flagList.append(FeatureFlagEntity(name: flag.key, isEnabled: value))
        }
        return flagList
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool {
        featureFlagsDict[key] as? Bool ?? false
    }
    
    public func configFeatureFlag(for key: FeatureFlagName, isEnabled: Bool) {
        var featureFlagsDict = featureFlagsDict
        featureFlagsDict[key] = isEnabled
        save(dict: featureFlagsDict)
    }
    
    public func removeFeatureFlag(for key: FeatureFlagName) {
        var featureFlagsDict = featureFlagsDict
        featureFlagsDict.removeValue(forKey: key)
        save(dict: featureFlagsDict)
    }
}
