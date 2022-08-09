import MEGADomain

extension PreferenceUseCase where T == PreferenceRepository {
    static var `default`: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository(userDefaults: UserDefaults.standard))
    }
    
    static var group: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: MEGAGroupIdentifier)!))
    }
}
