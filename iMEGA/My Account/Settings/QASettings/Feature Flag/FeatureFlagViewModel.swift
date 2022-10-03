import MEGADomain

enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case scheduleMeeting = "Schedule Meeting"
    case slideShowPreference = "Slide Show Preference"
    
    var isEnabled: Bool {
        switch self {
        case .scheduleMeeting: return false
        case .slideShowPreference: return false
        }
    }
}

final class FeatureFlagViewModel: ObservableObject {
    private var useCase: FeatureFlagUseCaseProtocol
    
    var featureFlagList: [FeatureFlagEntity] = FeatureFlagKey.allCases.map { FeatureFlagEntity(name: $0.rawValue, isEnabled: $0.isEnabled) }
    
    init(useCase: FeatureFlagUseCaseProtocol = FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)) {
        self.useCase = useCase
        self.syncUpFeatureFlags()
    }
}

//MARK: - Feature Flag List
extension FeatureFlagViewModel {

    private func syncUpFeatureFlags() {
        loadSavedFeatureFlags()
        saveNewFeatureFlags()
        cleanSavedFeatureFlags()
    }
    
    /// Updates `featureFlagList` values based on saved feature flags from data store
    private func loadSavedFeatureFlags() {
        let savedFeatureFlags = useCase.savedFeatureFlags()
        
        featureFlagList.enumerated().forEach { index, featureFlag in
            if let storedFeatureFlag = savedFeatureFlags.first(where: { $0.name == featureFlag.name }) {
                featureFlagList[index].isEnabled = storedFeatureFlag.isEnabled
            }
        }
    }
    
    /// Saves new feature flags on data store defined on `featureFlagList`
    func saveNewFeatureFlags() {
        let savedFeatureFlags = Set(useCase.savedFeatureFlags().map(\.name))
        let featureList = Set(featureFlagList.map(\.name))
        let newFeatures = featureList.subtracting(savedFeatureFlags)
        
        newFeatures.forEach { featureFlagName in
            if let featureFlag = featureFlagList.first(where: { $0.name == featureFlagName }) {
                saveFeatureFlag(featureFlag: featureFlag)
            }
        }
    }
    
    /// Removes feature flags on data store that are not defined on the `featureFlagList`
    func cleanSavedFeatureFlags() {
        let savedFeatureFlags = Set(useCase.savedFeatureFlags().map(\.name))
        let featureList = Set(featureFlagList.map(\.name))
        let nonExistingFeatureFlags = savedFeatureFlags.subtracting(featureList)
        
        nonExistingFeatureFlags.forEach { featureName in
            useCase.removeFeatureFlag(key: featureName)
        }
    }
    
    /// Saves feature flag to data store
    /// - Parameter featureFlag: `FeatureFlagEntity` values to be saved
    func saveFeatureFlag(featureFlag: FeatureFlagEntity) {
        useCase.configFeatureFlag(key: featureFlag.name, isEnabled: featureFlag.isEnabled)
    }
}
