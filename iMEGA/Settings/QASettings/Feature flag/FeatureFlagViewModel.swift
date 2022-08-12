import MEGADomain

enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case removeHomeImage = "Remove Home Image"
    case slideShow = "Slide Show"
    case contextMenuOnCameraUploadExplorer = "Context Menu On CameraUpload Explorer"
    case filterMenuOnCameraUploadExplorer = "Filter Menu On CameraUpload Explorer"
    
    var isEnabled: Bool {
        switch self {
        case .removeHomeImage: return false
        case .slideShow: return false
        case .contextMenuOnCameraUploadExplorer: return false
        case .filterMenuOnCameraUploadExplorer: return false
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
    private func saveNewFeatureFlags() {
        let savedFeatureFlags = useCase.savedFeatureFlags()
        
        let newFeatures = featureFlagList.filter { feature in
            savedFeatureFlags.notContains(where: { $0.name == feature.name })
        }
        
        newFeatures.forEach { featureFlag in
            saveFeatureFlag(featureFlag: featureFlag)
        }
    }
    
    /// Removes feature flags on data store that are not defined on the `featureFlagList`
    private func cleanSavedFeatureFlags() {
        let savedFeatureFlags = useCase.savedFeatureFlags()
        
        let nonExistingFeatureFlags = savedFeatureFlags.filter { feature in
            featureFlagList.notContains(where: { $0.name == feature.name })
        }
        
        nonExistingFeatureFlags.forEach { feature in
            useCase.removeFeatureFlag(key: feature.name)
        }
    }
    
    /// Saves feature flag to data store
    /// - Parameter featureFlag: `FeatureFlagEntity` values to be saved
    func saveFeatureFlag(featureFlag: FeatureFlagEntity) {
        useCase.configFeatureFlag(key: featureFlag.name, isEnabled: featureFlag.isEnabled)
    }
    
    /// Gets the latest feature flag value from data store
    /// - Parameter featureFlag: `FeatureFlagEntity` to be searched on data store
    /// - Returns: It returns the feature flag boolean value from data store
    func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        useCase.isFeatureFlagEnabled(for: key.rawValue)
    }
}
