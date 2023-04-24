import MEGADomain
import MEGAData

extension PreferenceUseCase where T == PreferenceRepository {
    static var `default`: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository.newRepo)
    }
    
    static var group: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: MEGAGroupIdentifier)!))
    }
}
