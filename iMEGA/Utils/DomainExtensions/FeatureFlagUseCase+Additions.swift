import MEGADomain
import MEGARepo

extension FeatureFlagUseCase where T == FeatureFlagRepository {
    
    static var featureFlagGroup: FeatureFlagUseCase {
        FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)
    }
    
}
