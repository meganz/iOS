import MEGADomain
import MEGAData

enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case scheduleMeeting = "Schedule Meeting"
    case createAlbum = "Create Album"
    case albumContextMenu = "Enable Album Context Menu"
    case newUpgradeAccountPlanUI = "New Upgrade Account Plan UI"
    case albumShareLink = "Album Share Link"
}

final class FeatureFlagViewModel: ObservableObject {
    private var useCase: FeatureFlagUseCaseProtocol
    
    var featureFlagList: [FeatureFlagEntity] = FeatureFlagKey.allCases.map { FeatureFlagEntity(name: $0.rawValue, isEnabled: false) }
    
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
