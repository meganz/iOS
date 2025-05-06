import MEGADomain
import MEGAPreference
import MEGARepo

extension PreferenceUseCase where T == PreferenceRepository {
    static var group: PreferenceUseCase {
        .init(repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: MEGAGroupIdentifier)!))
    }
}
